#!/usr/bin/env bash
set -euo pipefail

printf '\n== Repository ==\n'
git rev-parse --show-toplevel
git remote -v
git branch --show-current

printf '\n== Working tree ==\n'
git status --short --branch --untracked-files=all

printf '\n== Nested Git repositories ==\n'
find . -mindepth 2 -type d -name .git -not -path './.git/*' -print

printf '\n== Files larger than 10 MiB ==\n'
find . -type f -not -path './.git/*' -size +10M -print

printf '\n== Potential secret/config files ==\n'
find . -type f -not -path './.git/*' \( \
  -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.key' \
  -o -name '*.p12' -o -name '*.pfx' -o -name '*.jks' -o -name '*.keystore' \
  -o -name '*.pgpass' \
\) -print

printf '\n== Common credential-like text in unignored files ==\n'
git grep -nEI '(password|passwd|secret|api[_-]?key|access[_-]?token|private[_-]?key)[[:space:]]*[:=][[:space:]]*[^$<{[:space:]]+' -- . \
  ':!*.md' ':!*.example' ':!*.sample' || true

printf '\n== Ignored files summary ==\n'
git status --short --ignored | sed -n '1,200p'

printf '\nReview complete. Nothing was staged or committed.\n'
