#!/usr/bin/env bash
# Usage: scripts/reset.sh
# Restores the live config from baseline/, commits "reset: baseline" and pushes.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

assert_clean_main
restore_baseline
if [[ -z "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "Already at baseline; nothing to push."
  exit 0
fi
commit_and_push "reset: baseline"
