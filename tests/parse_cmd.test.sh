#!/usr/bin/env bash
# Tests for system/parse_cmd.sh — the deterministic inbox-verb parser. This is the
# security boundary that stops a gate verb being hallucinated from prose, so pin it.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/system/parse_cmd.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      got: %s\n' "$1" "${2:-}"; }
eq(){ local got; got=$(bash "$P" "$2"); [ "$got" = "$3" ] && ok "$1" || no "$1" "$got"; }

echo "parse_cmd.sh"
eq "gate verb approve → approve|KEY|"           "approve 5056"                              "approve|5056|"
eq "reject carries the reason text"             "reject 5056 redesign phase 2"              "reject|5056|redesign phase 2"
eq "note verb parses"                           "note 3092 slack decision here"             "note|3092|slack decision here"
eq "unknown verb is NOT coerced to a gate"      "lgtm ship it approve"                       "unknown||lgtm ship it approve"
eq "trailing ‹actor· ts› annotation is stripped" "approve 5056   ‹Jul 24 · abhinav›"        "approve|5056|"
eq "key trailing punctuation trimmed"           "recompute denali#3496 — CI;"               "recompute|denali#3496|— CI;"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mparse_cmd: %d passed\033[0m\n' "$PASS"; else printf '\033[31mparse_cmd: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
