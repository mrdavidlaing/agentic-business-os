#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd -- "$REPO_ROOT"

usage() {
  printf 'Usage: %s [--require-container]\n' "${0##*/}" >&2
}

require_container=false
case $# in
  0) ;;
  1)
    if [[ $1 == --require-container ]]; then
      require_container=true
    else
      usage
      exit 64
    fi
    ;;
  *)
    usage
    exit 64
    ;;
esac

in_container=false
if [[ ${AGENTIC_BUSINESS_OS_DEVCONTAINER:-} == 1 ]]; then
  in_container=true
fi

if [[ $require_container == true && $in_container == false ]]; then
  printf 'Error: --require-container requires AGENTIC_BUSINESS_OS_DEVCONTAINER=1.\n' >&2
  exit 1
fi

for tool in jq shellcheck shellspec; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Error: required tool is missing: %s\n' "$tool" >&2
    exit 1
  fi
done

jq empty .devcontainer/devcontainer.json

shell_manifest="$(mktemp "${TMPDIR:-/tmp}/agentic-business-os-shell-files.XXXXXX")"
readonly shell_manifest
trap 'rm -f -- "$shell_manifest"' EXIT

if ! find .devcontainer -type f \( -name '*.bash' -o -name '*_spec.sh' \) -print |
  LC_ALL=C sort >"$shell_manifest"; then
  printf 'Error: failed to discover shell files under .devcontainer.\n' >&2
  exit 1
fi

if [[ ! -s $shell_manifest ]]; then
  printf 'Error: no shell files found under .devcontainer.\n' >&2
  exit 1
fi

while IFS= read -r shell_file; do
  shellcheck "$shell_file"
done <"$shell_manifest"

if [[ $in_container == true ]]; then
  shellspec .devcontainer/spec
else
  shellspec \
    .devcontainer/spec/install_lazyvim_spec.sh \
    .devcontainer/spec/setup_agents_spec.sh \
    .devcontainer/spec/start_paperclip_spec.sh
  printf 'Container contract checks were skipped; run inside the devcontainer for full verification.\n'
fi
