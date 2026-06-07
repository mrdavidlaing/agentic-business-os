#!/usr/bin/env bash

set -euo pipefail

readonly starter_repository="https://github.com/LazyVim/starter.git"
readonly starter_commit="803bc181d7c0d6d5eeba9274d9be49b287294d99"
readonly target_dir="${HOME}/.config/nvim"

if [[ -e $target_dir ]]; then
  printf '%s\n' 'Neovim config already exists; preserving existing configuration.'
  exit 0
fi

mkdir -p "${HOME}/.config"
staging_dir="$(mktemp -d "${HOME}/.config/nvim.install.XXXXXX")"
readonly staging_dir
trap 'rm -rf -- "$staging_dir"' EXIT

git init --quiet "$staging_dir"
git -C "$staging_dir" remote add origin "$starter_repository"
git -C "$staging_dir" fetch --quiet --depth 1 origin "$starter_commit"
git -C "$staging_dir" checkout --quiet --detach FETCH_HEAD
rm -rf "$staging_dir/.git"
mv "$staging_dir" "$target_dir"

printf 'LazyVim starter installed at %s.\n' "$target_dir"
