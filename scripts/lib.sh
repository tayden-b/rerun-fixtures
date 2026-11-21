# Shared helpers for break.sh and reset.sh. Source, don't run.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

die() {
  echo "error: $*" >&2
  exit 1
}

# Paths of the live config files that have a pristine copy under baseline/.
baseline_files() {
  (cd baseline && find . -type f -name '*.tf' | sed 's#^\./##' | sort)
}

assert_clean_main() {
  [[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || die "check out main first"
  [[ -z "$(git status --porcelain --untracked-files=no)" ]] || die "working tree has uncommitted changes"
  git fetch -q origin main
  [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "main is not in sync with origin/main (git pull --ff-only)"
}

restore_baseline() {
  local f
  while read -r f; do
    mkdir -p "$(dirname "$f")"
    cp "baseline/$f" "$f"
  done < <(baseline_files)
}

commit_and_push() {
  local message="$1"
  local f
  while read -r f; do git add -- "$f"; done < <(baseline_files)
  git commit -q -m "$message"
  git push -q origin main
  local sha
  sha="$(git rev-parse HEAD)"
  echo "Pushed ${sha:0:7} \"${message}\" to main."
  print_actions_url "$sha"
}

print_actions_url() {
  local sha="$1" slug url=""
  slug="$(git remote get-url origin | sed -E 's#^.*github\.com[:/]##; s#\.git$##')"
  if command -v gh >/dev/null 2>&1; then
    for _ in 1 2 3 4 5 6; do
      url="$(gh run list --repo "$slug" --commit "$sha" --json url -q '.[0].url' 2>/dev/null || true)"
      [[ -n "$url" ]] && break
      sleep 5
    done
  fi
  echo "Actions run: ${url:-https://github.com/${slug}/actions?query=branch%3Amain}"
}
