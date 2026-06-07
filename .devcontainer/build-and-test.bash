#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

case "$(uname -m)" in
  x86_64|amd64) platform="linux/amd64" ;;
  aarch64|arm64) platform="linux/arm64" ;;
  *) echo "Unsupported host architecture: $(uname -m)" >&2; exit 1 ;;
esac

readonly image="agentic-business-os-devcontainer:test"

devcontainer build \
  --workspace-folder . \
  --platform "$platform" \
  --image-name "$image"

docker run --rm \
  --volume "$repo_root:/workspaces/agentic-business-os" \
  --workdir /workspaces/agentic-business-os \
  "$image" \
  .devcontainer/test.bash --require-container
