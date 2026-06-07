Describe '.devcontainer/setup-agents.bash'
  setup() {
    TEST_BIN="${SHELLSPEC_TMPBASE}/bin"
    rm -rf "$TEST_BIN"
    mkdir -p "$TEST_BIN"

    for command_name in claude opencode agy; do
      cat >"$TEST_BIN/$command_name" <<'EOF'
#!/usr/bin/env bash
exit 99
EOF
      chmod +x "$TEST_BIN/$command_name"
    done

    cat >"$TEST_BIN/env" <<'EOF'
#!/bin/bash
exec /usr/bin/env "$@"
EOF
    cat >"$TEST_BIN/grep" <<'EOF'
#!/bin/bash
exec /usr/bin/grep "$@"
EOF
    chmod +x "$TEST_BIN/env" "$TEST_BIN/grep"
  }

  BeforeEach 'setup'

  It 'does not fail when OPENCODE_API_KEY is missing'
    When run env -u OPENCODE_API_KEY PATH="$TEST_BIN" /bin/bash .devcontainer/setup-agents.bash
    The status should be success
    The output should include 'OPENCODE_API_KEY is not set'
    The output should include 'add OPENCODE_API_KEY as a Codespaces secret'
    The output should include 'rebuild the Codespace'
    The output should include 'OpenCode and Pi read OPENCODE_API_KEY directly'
    The output should include 'No credential files are generated'
  End

  It 'reports an available OPENCODE_API_KEY without printing it'
    When run env OPENCODE_API_KEY='do-not-print-this' PATH="$TEST_BIN" /bin/bash .devcontainer/setup-agents.bash
    The status should be success
    The output should include 'OPENCODE_API_KEY is available'
    The output should not include 'do-not-print-this'
  End

  It 'does not expose OPENCODE_API_KEY in an xtrace'
    When run env OPENCODE_API_KEY='do-not-print-this' PATH="$TEST_BIN" /bin/bash -x .devcontainer/setup-agents.bash
    The status should be success
    The output should not include 'do-not-print-this'
    The stderr should not include 'do-not-print-this'
  End

  It 'prints individual login and status guidance'
    When run env -u OPENCODE_API_KEY PATH="$TEST_BIN" /bin/bash .devcontainer/setup-agents.bash
    The status should be success
    The output should include 'claude'
    The output should include '/login'
    The output should include 'codex login'
    The output should include 'agy'
    The output should include 'Google OAuth'
    The output should include 'gh auth status'
  End

  It 'prints shared-key usage guidance without unsupported flags'
    When run env -u OPENCODE_API_KEY PATH="$TEST_BIN" /bin/bash .devcontainer/setup-agents.bash
    The status should be success
    The output should include 'run opencode'
    The output should include 'run pi'
  End

  It 'reports installed and missing commands from PATH'
    When run env -u OPENCODE_API_KEY PATH="$TEST_BIN" /bin/bash .devcontainer/setup-agents.bash
    The status should be success
    The output should include 'claude: installed'
    The output should include 'codex: missing'
    The output should include 'opencode: installed'
    The output should include 'pi: missing'
    The output should include 'agy: installed'
    The output should include 'gh: missing'
  End
End
