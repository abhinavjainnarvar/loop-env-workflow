#!/usr/bin/env bash
# voice-lint.sh — mechanical check of a draft against the owner's measured style.
#
# Prose rules can't enforce themselves (the lesson from the ECC analysis: enforce in
# code, not in instructions). Every check here is something the corpus measured at ~0%,
# so a hit is a real tell, not a taste call.
#
# Usage:
#   voice-lint.sh <file>             # lint a file
#   echo "draft text" | voice-lint.sh
#   voice-lint.sh --surface pr <file>   # surface: pr | jira | commit | chat (word budget)
# Exit: 0 clean · 1 hits found (so it can gate a publish step)

set -uo pipefail
SURFACE="any"
while [ $# -gt 0 ]; do
  case "$1" in
    --surface) SURFACE="$2"; shift 2;;
    *) FILE="$1"; shift;;
  esac
done
SRC="$(cat "${FILE:-/dev/stdin}")"
hits=0
flag() { hits=$((hits + 1)); printf '  \033[33m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }
has() { printf '%s' "$SRC" | grep -nE "$1" | head -3; }

echo "voice-lint (${SURFACE})"

# --- absolute tells (0% in 2,800 samples) ---
m=$(has '—|–')            && flag "em/en dash — he has never written one; use a comma or full stop" "$m"
m=$(has '^#{1,6} ')       && flag "markdown header — 0% of his messages" "$m"
m=$(has '^\|.*\|')        && flag "table — he writes none" "$m"
m=$(has '\*\*[^*]+\*\*')  && flag "bold — structure comes from a second sentence, not formatting" "$m"
m=$(has '^\s*[-*] ')      && flag "bullet list — 0 bullets in 360 PR comments and 2,224 messages" "$m"
# code fences are his ONLY on PR comments (17.8%: untagged pseudo-code / suggestion blocks)
if [ "$SURFACE" != "pr" ]; then
  m=$(has '^```') && flag "code fence — 0% outside PR comments" "$m"
fi
# `!` and 👍🙏🥳 are genuinely his in a PR review body ("LGTM!"), nowhere else
if [ "$SURFACE" != "pr" ]; then
  m=$(has '!')                  && flag "exclamation mark — 0 in his prose outside PR review bodies" "$m"
  m=$(has '[😀-🿿✅❌⚠🔴🟡🟢]') && flag "emoji — only 👍🙏🥳 in a PR review body, never elsewhere" "$m"
else
  m=$(has '[✅❌⚠🔴🟡🟢🚀]|:shipit:') && flag "status/rocket emoji — his PR repertoire is only 👍 🙏 🥳" "$m"
fi

# --- vocabulary he never uses ---
m=$(has '\b(kindly|as per|do the needful|revert back|could you)\b') \
  && flag "phrase he never uses (kindly/as per/do the needful/revert back/could you)" "$m"
m=$(has '\b(delve|leverage|seamless|robust|furthermore|moreover|utilise|utilize|holistic|comprehensive|myriad|plethora)\b') \
  && flag "heavy word — he asks for words engineers use daily" "$m"
m=$(has "I'd be happy to|great question|Let me know if you have any|I hope this helps") \
  && flag "assistant filler" "$m"
if [ "$SURFACE" != "pr" ]; then
  m=$(has '\bLGTM\b') && flag "LGTM — 0 occurrences outside PR comments" "$m"
fi
m=$(has "let's")          && flag "let's — he writes 'lets' (216 vs 3)" "$m"

# --- agent formulas ---
m=$(has 'Fixed in [0-9a-f]{7,}[[:space:]]*(—|-)') \
  && flag "'Fixed in <sha> —' formula — say what changed instead" "$m"
m=$(has '\b(Blocker|Should.fix|P[0-9] Badge|severity)\b') \
  && flag "severity label — he states the consequence, not a bucket" "$m"
m=$(has '\b(per review|as discussed|owner (decision|approved)|plan §)') \
  && flag "process narration — state the why itself or nothing" "$m"
m=$(has '[A-Za-z0-9_./-]+\.(ts|tsx|js|jsx|rb|erb|py|go|sh|json|md):[0-9]+') \
  && flag "file:line citation — he cites a GitHub permalink ending #L34-L37" "$m"

# --- length budget ---
words=$(printf '%s' "$SRC" | wc -w | tr -d ' ')
lines=$(printf '%s' "$SRC" | grep -c . || true)
case "$SURFACE" in
  commit) budget=12;; chat) budget=40;; pr) budget=60;; jira) budget=120;; *) budget=80;;
esac
[ "$words" -gt "$budget" ] && flag "long for ${SURFACE}: ${words} words (his median is 12; budget ~${budget})" \
  "cut content, don't rephrase — 'People wouldnt read so much.'"

# --- surface-specific ---
if [ "$SURFACE" = "pr" ]; then
  # He hedges STRUCTURALLY: a question, collective "we", or an explicit non-blocking label.
  # Lexical hedges are only 7.8% — requiring them would push drafts to the rare pattern.
  # bare imperatives ("Redundant", "Use spinner instead") are his 6% register on style
  # mechanics — too short to carry a frame, so don't nag them
  IS_TERSE=0; [ "$words" -le 6 ] && IS_TERSE=1
  IS_APPROVAL=0
  printf '%s' "$SRC" | grep -qiE '\b(lgtm|looks good|approving|approved with)\b' && IS_APPROVAL=1
  [ "$IS_APPROVAL" -eq 0 ] && [ "$IS_TERSE" -eq 0 ] && ! printf '%s' "$SRC" | grep -qiE '\?|\b(can we|should we|do we|shall we|lets|nit:)\b|not a big deal|non.?blocking|maybe for later' \
    && flag "peer-facing with no structural hedge" \
            "make it a question, or say 'we' instead of 'you', or label it 'nit:' — don't reach for 'not sure'"
  printf '%s' "$SRC" | grep -qiE "\byour call\b" \
    && flag "'your call' — never appears in 360 of his PR comments" ""
  printf '%s' "$SRC" | grep -qiE "\byou (should|need to|must|have to)\b|\byour code\b" \
    && flag "second-person directive — he uses 'we' (42%) over 'you' (6%)" ""
  printf '%s' "$SRC" | grep -qiE "\bgood catch\b" \
    && flag "'Good catch' is something he receives, not gives" ""
fi
if [ "$SURFACE" = "commit" ] && [ "$lines" -gt 1 ]; then
  flag "commit body present — 346 of his 414 commits have none" "subject only, unless there is a non-obvious why"
fi

echo
if [ "$hits" -eq 0 ]; then printf '\033[32mclean (%s words)\033[0m\n' "$words"; exit 0
else printf '\033[33m%d tell(s) — see ~/.claude/skills/voice/SKILL.md\033[0m\n' "$hits"; exit 1; fi
