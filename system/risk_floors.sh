#!/usr/bin/env bash
# Deterministic risk FLOORS from touched paths/terms (stdin). LLM may RAISE, never lower below these.
in=$(cat)
out=""
printf '%s' "$in" | grep -qiE 'auth|session|permission|passwd|password|secret|token|payment|billing|stripe|webhook|upload|attach|raw.?sql|saniti[sz]' && out="sec-pass=Y(FORCED: security-sensitive path/term)\n"
printf '%s' "$in" | grep -qiE 'migration|db/migrate|structure\.sql|schema\.rb|\bschema\b|terraform|\.tf([[:space:]]|$)|public.?api|/types/|graphql.*schema' && out="${out}hard-to-undo=Y(FORCED: schema/migration/infra/public-API)\n"
[ -z "$out" ] && out="no forced floors detected\n"
printf '%b' "$out"
