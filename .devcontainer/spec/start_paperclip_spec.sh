Describe '.devcontainer/start-paperclip.bash'
  setup() {
    TEST_BIN="${SHELLSPEC_TMPBASE}/bin"
    TEST_HOME="${SHELLSPEC_TMPBASE}/paperclip-home"
    CALL_LOG="${SHELLSPEC_TMPBASE}/paperclipai.calls"
    export TEST_BIN TEST_HOME CALL_LOG

    rm -rf "$TEST_BIN" "$TEST_HOME" "$CALL_LOG"
    mkdir -p "$TEST_BIN" "$TEST_HOME"

    # Mock paperclipai: record its arguments, then linger briefly so the
    # recorded background pid stays alive while assertions run.
    cat >"$TEST_BIN/paperclipai" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
sleep 2
EOF
    chmod +x "$TEST_BIN/paperclipai"
  }

  BeforeEach 'setup'

  It 'skips startup when paperclipai is not installed'
    # Pin PATH to the base system dirs (which have bash/coreutils for the
    # shebang) but exclude /usr/local/bin, where paperclipai is globally
    # installed in the real container image.
    When run env PAPERCLIP_HOME="$TEST_HOME" PATH="/usr/bin:/bin" .devcontainer/start-paperclip.bash
    The status should be success
    The stderr should include 'paperclipai not found'
    The path "$TEST_HOME/paperclip.pid" should not be exist
  End

  It 'onboards on first run when no config exists'
    When run env PAPERCLIP_HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/start-paperclip.bash
    The status should be success
    The output should include 'First run: onboarding Paperclip'
    The output should include 'http://127.0.0.1:3100'
    The file "$TEST_HOME/paperclip.pid" should be exist
    The contents of file "$CALL_LOG" should equal 'onboard --yes'
  End

  It 'runs (does not re-onboard) when a config already exists'
    mkdir -p "$TEST_HOME/instances/default"
    printf '%s\n' '{}' >"$TEST_HOME/instances/default/config.json"

    When run env PAPERCLIP_HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/start-paperclip.bash
    The status should be success
    The output should include 'Starting Paperclip'
    The file "$TEST_HOME/paperclip.pid" should be exist
    The contents of file "$CALL_LOG" should equal 'run'
  End

  It 'is idempotent when the server is already running'
    sleep 30 &
    live_pid=$!
    printf '%s\n' "$live_pid" >"$TEST_HOME/paperclip.pid"

    When run env PAPERCLIP_HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/start-paperclip.bash
    The status should be success
    The output should include 'already running'
    The file "$CALL_LOG" should not be exist

    kill "$live_pid" 2>/dev/null || true
  End

  It 'relaunches when the recorded pid is stale'
    # A pid that is not running.
    printf '%s\n' '999999' >"$TEST_HOME/paperclip.pid"

    When run env PAPERCLIP_HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/start-paperclip.bash
    The status should be success
    The output should include 'http://127.0.0.1:3100'
    The contents of file "$CALL_LOG" should equal 'onboard --yes'
  End
End
