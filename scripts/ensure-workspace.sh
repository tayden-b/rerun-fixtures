#!/usr/bin/env bash
# Idempotently create the HCP Terraform workspace this repo applies to.
# Needs TFE_TOKEN and TFE_ORG in the environment; only touches the workspace named below.
set -euo pipefail

: "${TFE_TOKEN:?TFE_TOKEN must be set}"
: "${TFE_ORG:?TFE_ORG must be set}"

WORKSPACE="${WORKSPACE:-rerun-fixtures}"
TF_VERSION_PREFIX="${TF_VERSION_PREFIX:-1.14.}"
DESCRIPTION="Rerun demo workspace — seeded failures; fixed by tayden-b/rerun"
API="${TFE_ADDRESS:-https://app.terraform.io}/api/v2"

api() {
  local method="$1" path="$2"
  shift 2
  curl -sS -X "$method" \
    -H "Authorization: Bearer ${TFE_TOKEN}" \
    -H "Content-Type: application/vnd.api+json" \
    -w '\n%{http_code}' "$@" "${API}${path}"
}

response="$(api GET "/organizations/${TFE_ORG}/workspaces/${WORKSPACE}")"
status="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "$status" == "200" ]]; then
  echo "Workspace ${WORKSPACE} exists: $(jq -r '.data.id' <<<"$body") (terraform $(jq -r '.data.attributes["terraform-version"]' <<<"$body"))"
  exit 0
elif [[ "$status" != "404" ]]; then
  echo "Unexpected HTTP ${status} checking workspace ${WORKSPACE}" >&2
  jq -r '.errors[]? | "  \(.title): \(.detail // "")"' <<<"$body" >&2 || true
  exit 1
fi

# Latest enabled, non-beta 1.14.x release HCP Terraform offers.
tf_version=""
page=1
while :; do
  versions="$(curl -sS -H "Authorization: Bearer ${TFE_TOKEN}" \
    "${API}/tool-versions?page%5Bsize%5D=100&page%5Bnumber%5D=${page}")"
  found="$(jq -r --arg p "$TF_VERSION_PREFIX" '.data[]? | select(.attributes.version | startswith($p))
    | select(.attributes.enabled and (.attributes.beta | not)) | .attributes.version' <<<"$versions")"
  tf_version="$(printf '%s\n%s\n' "$tf_version" "$found" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)"
  next="$(jq -r '.meta.pagination["next-page"] // empty' <<<"$versions")"
  [[ -z "$next" ]] && break
  page="$next"
done
if [[ -z "$tf_version" ]]; then
  echo "No enabled ${TF_VERSION_PREFIX}x Terraform version found in HCP Terraform" >&2
  exit 1
fi

payload="$(jq -n --arg name "$WORKSPACE" --arg version "$tf_version" --arg description "$DESCRIPTION" '{
  data: {
    type: "workspaces",
    attributes: {
      name: $name,
      "execution-mode": "remote",
      "auto-apply": true,
      "terraform-version": $version,
      description: $description
    }
  }
}')"

response="$(api POST "/organizations/${TFE_ORG}/workspaces" --data "$payload")"
status="${response##*$'\n'}"
body="${response%$'\n'*}"
if [[ "$status" != "201" ]]; then
  echo "Creating workspace ${WORKSPACE} failed with HTTP ${status}" >&2
  jq -r '.errors[]? | "  \(.title): \(.detail // "")"' <<<"$body" >&2 || true
  exit 1
fi
echo "Created workspace ${WORKSPACE}: $(jq -r '.data.id' <<<"$body") (terraform ${tf_version})"
