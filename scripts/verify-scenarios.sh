#!/usr/bin/env bash
# Usage: scripts/verify-scenarios.sh
# Offline check (Terraform CLI only): the baseline validates, and each scenario's patch
# applies cleanly, stays fmt-clean and fails (or passes) `terraform validate` as expected.
# Works on a temporary copy; the working tree is never modified.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Scenarios expected to fail before plan when run offline. Everything else must
# validate and only fails later on HCP Terraform (plan or apply).
declare -A FAILS_AT=(
  [missing-required-arg]=validate
  [undeclared-reference]=validate
  [removed-argument]=validate
  [dependency-cycle]=validate
  [provider-version-conflict]=init
  [module-source-typo]=init
)

export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${HOME}/.terraform.d/plugin-cache}"
export TF_IN_AUTOMATION=1
mkdir -p "$TF_PLUGIN_CACHE_DIR"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

stage_copy() {
  rm -rf "$work/tree"
  mkdir -p "$work/tree"
  (cd baseline && find . -type f -name '*.tf' -exec cp --parents {} "$work/tree/" \;)
  cp .terraform.lock.hcl "$work/tree/"
}

# Prints init|validate|ok: the first step that failed, or ok.
run_checks() {
  (
    cd "$work/tree"
    terraform init -backend=false -input=false -no-color >"$work/init.log" 2>&1 || { echo init; exit 0; }
    terraform validate -no-color >"$work/validate.log" 2>&1 || { echo validate; exit 0; }
    echo ok
  )
}

first_error() {
  grep -h -m1 '^Error:' "$work/init.log" "$work/validate.log" 2>/dev/null | head -n1 || true
}

failures=0
pass() { printf '  PASS  %-28s %s\n' "$1" "$2"; }
fail() { printf '  FAIL  %-28s %s\n' "$1" "$2"; failures=$((failures + 1)); }

echo "Baseline"
for f in $(cd baseline && find . -type f -name '*.tf' | sed 's#^\./##'); do
  cmp -s "baseline/$f" "$f" || fail "baseline" "$f differs from baseline/$f"
done
stage_copy
terraform fmt -check -recursive "$work/tree" >/dev/null || fail "baseline" "terraform fmt -check"
result="$(run_checks)"
[[ "$result" == ok ]] && pass "baseline" "validates" || fail "baseline" "expected to validate, failed at $result: $(first_error)"

echo "Scenarios"
for dir in scenarios/*/; do
  name="$(basename "$dir")"
  stage_copy
  rm -f "$work/init.log" "$work/validate.log"
  if ! (cd "$work/tree" && git apply "$REPO_ROOT/$dir/break.patch") 2>"$work/apply.log"; then
    fail "$name" "break.patch does not apply: $(head -n1 "$work/apply.log")"
    continue
  fi
  if ! terraform fmt -check -recursive "$work/tree" >/dev/null; then
    fail "$name" "terraform fmt -check fails after patch"
    continue
  fi
  expected="${FAILS_AT[$name]:-ok}"
  result="$(run_checks)"
  if [[ "$result" == "$expected" ]]; then
    if [[ "$expected" == ok ]]; then
      pass "$name" "validates (fails later on HCP Terraform)"
    else
      pass "$name" "fails at $result: $(first_error)"
    fi
  else
    fail "$name" "expected $expected, got $result $(first_error)"
  fi
done

echo
if ((failures)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "All scenarios behave as expected."
