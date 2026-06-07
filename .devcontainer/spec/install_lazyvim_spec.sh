Describe '.devcontainer/install-lazyvim.bash'
  setup() {
    TEST_HOME="${SHELLSPEC_TMPBASE}/home"
    TEST_BIN="${SHELLSPEC_TMPBASE}/bin"
    GIT_LOG="${SHELLSPEC_TMPBASE}/git.log"
    FETCH_FAILED_MARKER="${SHELLSPEC_TMPBASE}/fetch.failed"
    export TEST_HOME TEST_BIN GIT_LOG FETCH_FAILED_MARKER

    rm -rf "$TEST_HOME" "$TEST_BIN" "$GIT_LOG" "$FETCH_FAILED_MARKER"
    mkdir -p "$TEST_HOME" "$TEST_BIN"
    cat >"$TEST_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$GIT_LOG"

if [[ $1 == init && $2 == --quiet ]]; then
  mkdir -p "$3/.git"
elif [[ $1 == -C && $3 == fetch && ${GIT_FAIL_FETCH:-} == 1 ]]; then
  printf '%s\n' 'simulated fetch failure' >&2
  exit 1
elif [[ $1 == -C && $3 == fetch && -n ${GIT_FAIL_FETCH_ONCE:-} && ! -e $GIT_FAIL_FETCH_ONCE ]]; then
  touch "$GIT_FAIL_FETCH_ONCE"
  printf '%s\n' 'simulated one-time fetch failure' >&2
  exit 1
elif [[ $1 == -C && $3 == checkout ]]; then
  printf '%s\n' 'starter config' >"$2/init.lua"
fi
EOF
    chmod +x "$TEST_BIN/git"
    cat >"$TEST_BIN/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == -T || ${1:-} == --no-target-directory ]]; then
  printf '%s\n' 'GNU-only mv option is not portable' >&2
  exit 64
fi

exec /bin/mv "$@"
EOF
    chmod +x "$TEST_BIN/mv"
  }

  BeforeEach 'setup'

  It 'preserves an existing Neovim configuration exactly'
    mkdir -p "$TEST_HOME/.config/nvim"
    printf '%s\n' 'personal config' >"$TEST_HOME/.config/nvim/init.lua"

    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/install-lazyvim.bash
    The status should be success
    The output should include 'preserving existing configuration'
    The contents of file "$TEST_HOME/.config/nvim/init.lua" should equal 'personal config'
    The file "$GIT_LOG" should not be exist
  End

  It 'preserves an existing file at the target path'
    mkdir -p "$TEST_HOME/.config"
    printf '%s\n' 'personal config file' >"$TEST_HOME/.config/nvim"

    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/install-lazyvim.bash
    The status should be success
    The output should include 'preserving existing configuration'
    The contents of file "$TEST_HOME/.config/nvim" should equal 'personal config file'
    The file "$GIT_LOG" should not be exist
  End

  It 'installs the pinned LazyVim starter into a clean home'
    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/install-lazyvim.bash
    The status should be success
    The output should include 'LazyVim starter installed'
    The directory "$TEST_HOME/.config/nvim" should be exist
    The contents of file "$GIT_LOG" should include 'remote add origin https://github.com/LazyVim/starter.git'
    The contents of file "$GIT_LOG" should include 'fetch --quiet --depth 1 origin 803bc181d7c0d6d5eeba9274d9be49b287294d99'
    The contents of file "$GIT_LOG" should include 'checkout --quiet --detach FETCH_HEAD'
  End

  It 'removes Git metadata from the installed target'
    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" .devcontainer/install-lazyvim.bash
    The status should be success
    The output should include 'LazyVim starter installed'
    The directory "$TEST_HOME/.config/nvim/.git" should not be exist
  End

  It 'removes a partial installation when fetch fails'
    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" GIT_FAIL_FETCH=1 .devcontainer/install-lazyvim.bash
    The status should be failure
    The stderr should include 'simulated fetch failure'
    The path "$TEST_HOME/.config/nvim" should not be exist
  End

  It 'can retry successfully after a failed fetch'
    # shellcheck disable=SC2016 # Variables expand in the nested shell.
    When run env HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" GIT_FAIL_FETCH_ONCE="$FETCH_FAILED_MARKER" bash -c '
      if .devcontainer/install-lazyvim.bash >/dev/null 2>&1; then
        exit 10
      fi
      if [[ -e $HOME/.config/nvim ]]; then
        exit 11
      fi
      .devcontainer/install-lazyvim.bash
    '
    The status should be success
    The output should include 'LazyVim starter installed'
    The directory "$TEST_HOME/.config/nvim" should be exist
  End
End
