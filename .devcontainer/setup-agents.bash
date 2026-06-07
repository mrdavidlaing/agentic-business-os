#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' 'Agent command readiness:'
for command_name in claude codex opencode pi agy gh paperclipai; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  %s: installed\n' "$command_name"
  else
    printf '  %s: missing\n' "$command_name"
  fi
done

printf '\n%s\n' 'Shared API key:'
if (set +o pipefail; env | grep -q '^OPENCODE_API_KEY=.'); then
  printf '%s\n' '  OPENCODE_API_KEY is available.'
else
  printf '%s\n' '  OPENCODE_API_KEY is not set.'
  printf '%s\n' '  To configure it, add OPENCODE_API_KEY as a Codespaces secret, then rebuild the Codespace.'
fi
printf '%s\n' '  OpenCode and Pi read OPENCODE_API_KEY directly from the environment.'
printf '%s\n' '  No credential files are generated.'
printf '%s\n' '  To use the shared key, run opencode or run pi.'

printf '\n%s\n' 'Individual account setup:'
printf '%s\n' '  Claude: run claude, then enter /login.'
printf '%s\n' '  Codex: run codex login.'
printf '%s\n' '  Antigravity: run agy and follow the Google OAuth guidance.'
printf '%s\n' '  GitHub CLI: run gh auth status to check authentication.'
