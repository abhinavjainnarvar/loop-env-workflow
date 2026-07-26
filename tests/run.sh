#!/usr/bin/env bash
# Run every *.test.sh in this dir. Exit non-zero if any suite fails.
set -uo pipefail
cd "$(dirname "$0")"
fail=0
for t in *.test.sh *.e2e.sh; do
  echo "── $t ────────────────────────────────────"
  bash "$t" || fail=1
  echo
done
[ "$fail" -eq 0 ] && echo "ALL SUITES PASSED" || echo "SOME SUITES FAILED"
exit "$fail"
