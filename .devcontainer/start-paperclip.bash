#!/usr/bin/env bash

# Start Paperclip (https://github.com/paperclipai/paperclip) as a background
# service inside this dev container.
#
# Topology: bundled in the dev container, trusted local loopback, no login.
# `paperclipai run` auto-onboards to trusted/loopback mode on first run and then
# serves the UI + API on http://127.0.0.1:3100. With no DATABASE_URL set, the
# server provisions an embedded PostgreSQL cluster under PAPERCLIP_HOME on first
# start (binaries are downloaded once).
#
# This script is the devcontainer postStartCommand: it must return promptly, so
# the server is launched detached and logs to a file. It is idempotent -- a
# second invocation while the server is already running is a no-op.

set -euo pipefail

paperclip_home="${PAPERCLIP_HOME:-${HOME}/.paperclip}"
readonly paperclip_home
log_file="${paperclip_home}/paperclip.log"
pid_file="${paperclip_home}/paperclip.pid"
readonly log_file pid_file

if ! command -v paperclipai >/dev/null 2>&1; then
  printf '%s\n' 'Paperclip is not installed (paperclipai not found on PATH); skipping startup.' >&2
  exit 0
fi

mkdir -p "$paperclip_home"

if [[ -f $pid_file ]]; then
  existing_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n $existing_pid ]] && kill -0 "$existing_pid" 2>/dev/null; then
    printf 'Paperclip is already running (pid=%s); leaving it in place.\n' "$existing_pid"
    printf 'UI: http://127.0.0.1:3100  Logs: %s\n' "$log_file"
    exit 0
  fi
  rm -f "$pid_file"
fi

printf 'Starting Paperclip (trusted local loopback) on http://127.0.0.1:3100 ...\n'
nohup paperclipai run >>"$log_file" 2>&1 &
paperclip_pid=$!
disown "$paperclip_pid" 2>/dev/null || true
printf '%s\n' "$paperclip_pid" >"$pid_file"

printf 'Paperclip launched (pid=%s).\n' "$paperclip_pid"
printf 'UI: http://127.0.0.1:3100  Logs: %s\n' "$log_file"
printf 'First start downloads embedded PostgreSQL and may take a minute.\n'
