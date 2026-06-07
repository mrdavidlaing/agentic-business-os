#!/usr/bin/env bash

# Start Paperclip (https://github.com/paperclipai/paperclip) as a background
# service inside this dev container.
#
# Topology: bundled in the dev container, trusted local loopback, no login.
# First run only (no config yet): `paperclipai onboard --yes` writes the
# quickstart config (trusted local loopback) and starts serving on
# http://127.0.0.1:3100. `onboard` is used here, not `run`, because `run` cannot
# self-onboard in a non-interactive shell (the postStartCommand has no TTY).
# Every later start: a config exists, so we use `paperclipai run` directly. With
# no DATABASE_URL set, the server provisions an embedded PostgreSQL cluster under
# PAPERCLIP_HOME on first start (binaries are downloaded once).
#
# This script is the devcontainer postStartCommand: it must return promptly, so
# the server is launched detached and logs to a file. It is idempotent -- a
# second invocation while the server is already running is a no-op.

set -euo pipefail

paperclip_home="${PAPERCLIP_HOME:-${HOME}/.paperclip}"
readonly paperclip_home
log_file="${paperclip_home}/paperclip.log"
pid_file="${paperclip_home}/paperclip.pid"
instance_id="${PAPERCLIP_INSTANCE_ID:-default}"
config_file="${paperclip_home}/instances/${instance_id}/config.json"
readonly log_file pid_file instance_id config_file

if ! command -v paperclipai >/dev/null 2>&1; then
  printf '%s\n' 'Paperclip is not installed (paperclipai not found on PATH); skipping startup.' >&2
  exit 0
fi

# Fail soft: a sidecar that cannot start must not block the whole dev container.
if ! mkdir -p "$paperclip_home" 2>/dev/null || [[ ! -w $paperclip_home ]]; then
  printf 'Cannot write PAPERCLIP_HOME (%s); skipping Paperclip startup.\n' "$paperclip_home" >&2
  printf 'Point PAPERCLIP_HOME at a writable path (e.g. inside the workspace folder, not a\n' >&2
  printf 'root-owned dir like /workspaces) and restart the container.\n' >&2
  exit 0
fi

if [[ -f $pid_file ]]; then
  existing_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n $existing_pid ]] && kill -0 "$existing_pid" 2>/dev/null; then
    printf 'Paperclip is already running (pid=%s); leaving it in place.\n' "$existing_pid"
    printf 'UI: http://127.0.0.1:3100  Logs: %s\n' "$log_file"
    exit 0
  fi
  rm -f "$pid_file"
fi

if [[ -f $config_file ]]; then
  # Steady state: config already written, so just run. `run` is non-interactive
  # safe once a config exists.
  printf 'Starting Paperclip on http://127.0.0.1:3100 ...\n'
  nohup paperclipai run >>"$log_file" 2>&1 &
else
  # First run only: onboard with quickstart defaults (trusted local loopback),
  # which writes the config and starts serving. `run` cannot self-onboard in a
  # non-interactive shell (the postStartCommand has no TTY).
  printf 'First run: onboarding Paperclip (trusted local loopback) on http://127.0.0.1:3100 ...\n'
  nohup paperclipai onboard --yes >>"$log_file" 2>&1 &
fi
paperclip_pid=$!
disown "$paperclip_pid" 2>/dev/null || true
printf '%s\n' "$paperclip_pid" >"$pid_file"

printf 'Paperclip launched (pid=%s).\n' "$paperclip_pid"
printf 'UI: http://127.0.0.1:3100  Logs: %s\n' "$log_file"
printf 'First start downloads embedded PostgreSQL and may take a minute.\n'
