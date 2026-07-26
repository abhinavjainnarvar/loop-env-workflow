#!/usr/bin/env bash
# Deterministic PR gate from the world (no LLM eyeballing). Usage: pr_state.sh <repo> <num>
repo="$1"; num="$2"; owner=${repo%/*}; name=${repo#*/}
gh auth switch --user "${GH_ACCT:-abhinavjainnarvar}" >/dev/null 2>&1
j=$(gh pr view "$num" --repo "$repo" --json state,mergeable,reviewDecision 2>/dev/null)
state=$(printf '%s' "$j" | jq -r '.state // "?"')
mergeable=$(printf '%s' "$j" | jq -r '.mergeable // "?"')
review=$(printf '%s' "$j" | jq -r '.reviewDecision // "NONE"')
ci=$(gh pr checks "$num" --repo "$repo" --json state \
  --jq 'if length==0 then "none" elif any(.[];.state=="FAILURE" or .state=="ERROR" or .state=="CANCELLED") then "failing" elif any(.[];.state=="PENDING" or .state=="IN_PROGRESS" or .state=="QUEUED") then "pending" else "green" end' 2>/dev/null)
# UNRESOLVED review threads (bot OR human) — actionable feedback. A raw comment
# count won't do: a resolved thread isn't actionable, and the gate must escalate
# on unresolved ones even without a formal CHANGES_REQUESTED review.
unresolved=$(gh api graphql -f owner="$owner" -f name="$name" -F num="$num" \
  -f query='query($owner:String!,$name:String!,$num:Int!){repository(owner:$owner,name:$name){pullRequest(number:$num){reviewThreads(first:100){nodes{isResolved}}}}}' \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false)]|length' 2>/dev/null)
[ "$unresolved" -ge 0 ] 2>/dev/null || unresolved=0
if   [ "$state" = "MERGED" ]; then gate="done"
elif [ "$ci" = "failing" ];   then gate="pr-ci-failing"
elif [ "$review" = "CHANGES_REQUESTED" ] || [ "${unresolved:-0}" -gt 0 ]; then gate="pr-comments"  # escalate on unresolved threads, not just formal CHANGES_REQUESTED
elif [ "$ci" = "pending" ];   then gate="reviewing(ci)"
elif [ "$ci" = "green" ] || [ "$ci" = "none" ]; then gate="pr-clean"
else gate="reviewing"; fi
printf 'state=%s mergeable=%s review=%s ci=%s unresolved_threads=%s => gate=%s\n' "$state" "$mergeable" "$review" "$ci" "$unresolved" "$gate"
