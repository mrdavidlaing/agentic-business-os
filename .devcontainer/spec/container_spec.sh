Describe 'agentic-business-os devcontainer image'
  It 'sets locale, terminal, container, and updater environment defaults' dockerfile
    When call printf '%s|%s|%s|%s|%s|%s|%s' \
      "${LANG:-}" \
      "${LC_ALL:-}" \
      "${TERM:-}" \
      "${COLORTERM:-}" \
      "${AGENTIC_BUSINESS_OS_DEVCONTAINER:-}" \
      "${AGY_CLI_DISABLE_AUTO_UPDATE:-}" \
      "${DISABLE_AUTOUPDATER:-}"
    The output should equal 'C.UTF-8|C.UTF-8|xterm-256color|truecolor|1|true|1'
  End

  Context 'Dockerfile commands'
    Parameters
      node
      npm
      python3
      pip3
      git
      git-lfs
      curl
      jq
      make
      gcc
      g++
      shellcheck
      shellspec
      nvim
      zellij
      sshx
      claude
      codex
      opencode
      pi
      agy
      paperclipai
    End

    It "provides $1" dockerfile
      When call command -v "$1"
      The status should be success
      The output should not equal ''
    End
  End

  It 'provides gh through the devcontainer feature' gh-feature
    When call command -v gh
    The status should be success
    The output should not equal ''
  End

  It 'pins Node.js' dockerfile
    When run node --version
    The output should equal 'v22.22.3'
  End

  It 'uses Python 3.12 from the pinned devcontainer base' dockerfile
    When run python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
    The output should equal '3.12'
  End

  It 'pins ShellCheck' dockerfile
    When run shellcheck --version
    The output should include 'version: 0.11.0'
  End

  It 'pins ShellSpec' dockerfile
    When run sh -c 'shellspec --version'
    The output should equal '0.28.1'
  End

  It 'pins sshx' dockerfile
    When run sshx --version
    The output should include '0.4.1'
  End

  It 'pins Zellij' dockerfile
    When run zellij --version
    The output should include '0.44.3'
  End

  It 'pins Neovim' dockerfile
    When run nvim --version
    The first line of output should include 'NVIM v0.12.2'
  End

  It 'pins the npm-installed agents' dockerfile
    When run sh -c 'claude --version && codex --version && opencode --version && pi --version 2>&1'
    The output should include '2.1.168'
    The output should include '0.137.0'
    The output should include '1.16.2'
    The output should include '0.78.1'
  End

  It 'pins Antigravity' dockerfile
    When run agy --version
    The output should include '1.0.6'
  End

  It 'pins Paperclip' dockerfile
    When run paperclipai --version
    The output should include '2026.529.0'
  End
End
