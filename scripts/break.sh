#!/usr/bin/env bash
# Usage: scripts/break.sh <scenario>
# Resets main to the baseline, applies scenarios/<scenario>/break.patch, commits and pushes.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

name="${1:-}"
[[ -n "$name" ]] || die "usage: scripts/break.sh <scenario> (one of: $(ls scenarios | grep -v '\.md$' | tr '\n' ' '))"
patch="scenarios/${name}/break.patch"
[[ -f "$patch" ]] || die "no such scenario: ${name}"

assert_clean_main
restore_baseline
git apply "$patch" || { git checkout -- .; die "${patch} does not apply to the baseline"; }
commit_and_push "scenario: ${name}"
