#!/usr/bin/env bash
# Deterministically parse ONE inbox line → "verb|key|text". Unknown verb → "unknown||<line>".
# The loop MUST use this for gate verbs so it can't HALLUCINATE an approval from prose.
line="$*"
core=$(printf '%s' "$line" | sed -E 's/[[:space:]]*‹[^›]*›[[:space:]]*$//')   # strip helper annotation
verb=$(printf '%s' "$core" | awk '{print tolower($1)}')
case "$verb" in
  ingest|approve|reject|changes|hold|resume|retry|priority|drop|ask|recompute|note) ;;
  *) printf 'unknown||%s\n' "$line"; exit 0 ;;
esac
key=$(printf '%s' "$core" | awk '{print $2}' | sed 's/[:,;]*$//')
text=$(printf '%s' "$core" | sed -E 's/^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]*//; s/^:[[:space:]]*//')
printf '%s|%s|%s\n' "$verb" "$key" "$text"
