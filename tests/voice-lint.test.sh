#!/usr/bin/env bash
# Regression tests for skills/voice/voice-lint.sh.
#
# The fixtures are REAL samples from the mined corpus, which is the point: the first
# version of this lint rejected his actual PR comments (it demanded the lexical hedge
# that appears in only 7.8% of them, and banned LGTM — his most common approval). These
# tests pin the corpus so a future tweak can't re-introduce that class of error.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$ROOT/skills/voice/voice-lint.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

# clean <surface> <text> <label>  — a real sample of his must pass
clean(){ if printf '%s' "$2" | bash "$LINT" --surface "$1" >/dev/null 2>&1; then ok "$3"; \
  else no "$3" "$(printf '%s' "$2" | bash "$LINT" --surface "$1" | grep '✗' | head -2 | tr '\n' ' ')"; fi; }
# flags <surface> <text> <label> — agent-shaped prose must be caught
flags(){ local n; n=$(printf '%s' "$2" | bash "$LINT" --surface "$1" 2>/dev/null | grep -c '✗' || true)
  [ "${n:-0}" -ge 1 ] && ok "$3 (${n} tell/s)" || no "$3" "not flagged"; }

echo "voice-lint"

# --- his real PR comments (corpus-pr-reviews.md) must all be clean ---
clean pr "Can we move this to a constant? It is used in two more places." "question-framed suggestion"
clean pr "Do we need this check here?" "bare question"
clean pr "nit: lets rename this to returnItem, it is not a line item anymore." "nit label + 'lets'"
clean pr "Redundant" "bare imperative (his 6% register, too short to nag)"
clean pr "LGTM! Minor comments added." "his most common approval shape"
clean pr "Looks good. Just left one comment." "approval variant"
clean pr "Approving assuming the changes have been tested." "caveated approval"
clean pr "Not sure how this created the issue but lets deploy and check." "lexical hedge variant"

# --- other surfaces ---
clean commit "fix(shop-now): preserve market subfolder locale in dynamic redirect" "commit subject only"
clean chat "is loop running" "chat: question without a ?"
clean jira "Currently the dropzone stays inert once an image exists, so replacing it means removing first. We need click to replace. It is irritating for the merchant." "jira Currently/We-need frame"

# --- agent tells must be caught ---
flags pr "You should move this to a constant — it is more robust that way." "em dash + you-directive + heavy word"
flags pr "**Blocker (P1):** this is wrong (Section.tsx:86)." "bold + severity + file:line"
flags pr "Good catch! Your call on whether to fix it." "'Good catch' given + 'your call'"
flags pr "Fixed in ac0938ca — gated the handler." "'Fixed in <sha> —' formula"
flags chat "Let's use a more seamless approach, kindly confirm." "let's + seamless + kindly"
flags jira "I'd be happy to delve into this further." "assistant filler + delve"
flags commit "$(printf 'fix: thing\n\nA longer body explaining what the reader can already see.')" "commit body present"
flags pr "$(printf -- '- first point\n- second point')" "bullet list"

# --- exit code is usable as a gate ---
printf 'Do we need this?' | bash "$LINT" --surface pr >/dev/null 2>&1 && rc0=0 || rc0=1
printf 'This is — wrong' | bash "$LINT" --surface pr >/dev/null 2>&1 && rc1=0 || rc1=1
{ [ "$rc0" -eq 0 ] && [ "$rc1" -eq 1 ]; } && ok "exit 0 clean / 1 on tells (gate-able)" || no "exit codes" "clean=$rc0 dirty=$rc1"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mvoice-lint: %d passed\033[0m\n' "$PASS"; else printf '\033[31mvoice-lint: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
