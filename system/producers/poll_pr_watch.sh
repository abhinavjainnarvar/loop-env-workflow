#!/usr/bin/env bash
# PRODUCER (plain script, ZERO Claude tokens) — writes ONLY to the inbox, never board.md:
#  (1) open PRs I authored that aren't on the board → spec stub + `ingest <KEY>`
#  (2) when a BOARD PR's activity/CI fingerprint changes → append `recompute <repo>#<num>` to the inbox
#      (the loop drains it and recomputes that PR — sooner than its heartbeat)
# Dedup: pr_seen.txt (auto-add) + per-PR .fp file (change detection). First run seeds, surfaces nothing.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; APPEND="$HERE/inbox_append.sh"
ST="$HERE/state"; SEEN="$ST/pr_seen.txt"; mkdir -p "$ST"; touch "$SEEN"
BOARD="${BOARD:-$HOME/planning/boards/board.md}"; TIX="$HOME/planning/boards/tickets"
gh auth switch --user "${GH_ACCT:-abhinavjainnarvar}" >/dev/null 2>&1

proj_of() { [ "$1" = "narvar/denali" ] && echo denali || echo szero; }
fp() { # repo num -> fingerprint that triggers a recompute (explicitly incl. new comments)
  gh pr view "$2" --repo "$1" --json state,reviewDecision,comments,reviews \
     --jq '[.state,.reviewDecision,(.comments|length),(.reviews|length)]|join("|")' 2>/dev/null  # NOTE: updatedAt dropped — it ticks on every CI poll (flap noise)
  gh pr checks "$2" --repo "$1" --json bucket --jq 'if any(.[].bucket; .=="fail") then "fail" elif any(.[].bucket; .=="pending") then "pending" else "pass" end' 2>/dev/null  # CI CONCLUSION not per-check list — only flips on a real pending->pass/fail transition
  gh api "repos/$1/pulls/$2/comments" --jq 'length' 2>/dev/null   # inline review-thread comments
}

# (1) auto-add my open PRs not already on the board
SEED=0; [ ! -s "$SEEN" ] && SEED=1
gh search prs --author=@me --state=open --limit 50 \
   --json number,url,title,repository \
   --jq '.[] | [.repository.nameWithOwner, (.number|tostring), .url, .title] | @tsv' 2>/dev/null \
 | while IFS=$'\t' read -r repo num url title; do
    sig="$repo#$num"
    grep -qxF "$sig" "$SEEN" && continue
    echo "$sig" >> "$SEEN"
    [ "$SEED" -eq 1 ] && continue
    grep -qF "$url" "$BOARD" $TIX/*/review.md 2>/dev/null && continue   # already tracked
    p=$(proj_of "$repo"); KEY="PR-$p-$num"
    if [ ! -f "$TIX/$KEY/spec.md" ]; then
      mkdir -p "$TIX/$KEY"
      printf '# %s — %s\n\n- PR[%s]: %s\n- Producer-surfaced (pr-watch: authored PR not on board) — MAINTAIN row. NEEDS TRIAGE.\n' \
        "$KEY" "$title" "$p" "$url" > "$TIX/$KEY/spec.md"
    fi
    "$APPEND" "ingest $KEY"
  done
[ "$SEED" -eq 1 ] && echo "seeded pr_seen with my open PRs (surfaced 0)"

# (2) change-signal for board PRs (parse PR[<proj>]: urls from review.md)
grep -rhoE 'https://github\.com/[^ ]+/pull/[0-9]+' $TIX/*/review.md 2>/dev/null | sort -u \
 | while read -r url; do
    repo=$(echo "$url" | sed -E 's#https://github.com/([^/]+/[^/]+)/pull/.*#\1#')
    num=$(echo "$url" | grep -oE '[0-9]+$')
    f="$ST/fp_$(echo "$repo/$num" | tr '/#' '__').txt"
    cur=$(fp "$repo" "$num"); prev=$(cat "$f" 2>/dev/null)
    # Empty-read guard: a transient gh 404 returns an error body instead of counts.
    # Without this we'd write that garbage into the .fp; the next poll then reads
    # garbage->real as a "change" and appends a spurious recompute (the flap that woke
    # the loop twice on 2026-06-24). If the fetch isn't well-formed — error body, or a
    # non-numeric comments/reviews/inline count — skip this PR this round: keep the
    # prior .fp, surface nothing. Legit 0 counts pass; only garbage is rejected.
    gl1=$(printf '%s\n' "$cur" | sed -n 1p)
    gcc=$(echo "$gl1" | cut -d'|' -f3); gcr=$(echo "$gl1" | cut -d'|' -f4)
    gci=$(printf '%s\n' "$cur" | sed -n 3p)
    case "$cur" in *'Not Found'*|*'"message"'*|*documentation_url*) continue;; esac
    case "$gcc" in ''|*[!0-9]*) continue;; esac
    case "$gcr" in ''|*[!0-9]*) continue;; esac
    case "$gci" in ''|*[!0-9]*) continue;; esac
    [ "$cur" = "$prev" ] && continue
    echo "$cur" > "$f"
    if [ -z "$prev" ]; then       # first sighting of a board PR (fp already recorded above)
      # Surface PRE-EXISTING activity ONCE rather than silently absorbing it into the
      # baseline — the #2795 blind spot: comments/reviews that predate the first fingerprint.
      # Fresh PRs (0/0/0) stay silent; only board-tracked PRs with real activity signal.
      el1=$(printf '%s\n' "$cur" | sed -n 1p)
      ec=$(echo "$el1" | cut -d'|' -f3); er=$(echo "$el1" | cut -d'|' -f4); ei=$(printf '%s\n' "$cur" | sed -n 3p)
      if { [ "${ec:-0}" -gt 0 ] || [ "${er:-0}" -gt 0 ] || [ "${ei:-0}" -gt 0 ]; } 2>/dev/null; then
        grep -rlF "$url" $TIX/*/review.md >/dev/null 2>&1 \
          && "$APPEND" "recompute $repo#$num — existing on first sighting: ${ec:-0} comments / ${er:-0} reviews / ${ei:-0} inline (review pre-existing activity)"
      fi
      continue
    fi
    tdir=$(grep -rlF "$url" $TIX/*/review.md 2>/dev/null | head -1)
    [ -z "$tdir" ] && continue
    # Level-1 delta: record WHAT changed (counts / CI / state) in the breadcrumb
    pl1=$(printf '%s\n' "$prev" | sed -n 1p); cl1=$(printf '%s\n' "$cur" | sed -n 1p); delta=""
    pc=$(echo "$pl1"|cut -d'|' -f3); cc=$(echo "$cl1"|cut -d'|' -f3); [ "$cc" != "$pc" ] && delta="$delta comments ${pc}->${cc};"
    pv=$(echo "$pl1"|cut -d'|' -f4); cv=$(echo "$cl1"|cut -d'|' -f4); [ "$cv" != "$pv" ] && delta="$delta reviews ${pv}->${cv};"
    pi=$(printf '%s\n' "$prev"|sed -n 3p); ci=$(printf '%s\n' "$cur"|sed -n 3p); [ "$ci" != "$pi" ] && delta="$delta inline-comments ${pi}->${ci};"
    pchk=$(printf '%s\n' "$prev"|sed -n 2p); cchk=$(printf '%s\n' "$cur"|sed -n 2p); [ "$cchk" != "$pchk" ] && delta="$delta CI;"
    pst=$(echo "$pl1"|cut -d'|' -f1-2); cst=$(echo "$cl1"|cut -d'|' -f1-2); [ "$cst" != "$pst" ] && delta="$delta state/review;"
    [ -z "$delta" ] && delta=" activity;"
    "$APPEND" "recompute $repo#$num —$delta"
  done
exit 0
