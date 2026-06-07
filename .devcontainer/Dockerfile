# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

ARG TARGETARCH
ARG NODE_VERSION=22.22.3
ARG SHELLCHECK_VERSION=0.11.0
ARG SHELLSPEC_VERSION=0.28.1
ARG NEOVIM_VERSION=0.12.2
ARG ZELLIJ_VERSION=0.44.3
ARG SSHX_VERSION=0.4.1
ARG CLAUDE_CODE_VERSION=2.1.168
ARG CODEX_VERSION=0.137.0
ARG OPENCODE_VERSION=1.16.2
ARG PI_VERSION=0.78.1
ARG AGY_VERSION=1.0.6
ARG PAPERCLIP_VERSION=2026.529.0

# -----------------------------------------------------------------------------
# Layer 1: Base OS and user utilities
# -----------------------------------------------------------------------------
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    bash build-essential ca-certificates curl git git-lfs jq locales sudo \
    unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Layer 2: Architecture mapping and language runtimes
# -----------------------------------------------------------------------------
RUN case "${TARGETARCH}" in \
      amd64) node_arch=x64; node_sha=2e5d13569282d016861fae7c8f935e741693c269101a5bebcf761a5376d1f99f ;; \
      arm64) node_arch=arm64; node_sha=1c4a9933a5e45bc88f54f70b5f91232c127ec49f1a5989d23fb85824c7adf9b7 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && archive="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${archive}" -o "/tmp/${archive}" \
    && echo "${node_sha}  /tmp/${archive}" | sha256sum -c - \
    && tar -xJf "/tmp/${archive}" -C /usr/local --strip-components=1 \
    && rm "/tmp/${archive}"

# -----------------------------------------------------------------------------
# Layer 3: Shell authoring and test tools
# -----------------------------------------------------------------------------
RUN case "${TARGETARCH}" in \
      amd64) sc_arch=x86_64; sc_sha=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198 ;; \
      arm64) sc_arch=aarch64; sc_sha=12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588 ;; \
      *) exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${sc_arch}.tar.xz" -o /tmp/shellcheck.tar.xz \
    && echo "${sc_sha}  /tmp/shellcheck.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/shellcheck.tar.xz -C /tmp \
    && install -m 0755 "/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck \
    && rm -rf /tmp/shellcheck*

RUN curl -fsSL "https://github.com/shellspec/shellspec/releases/download/${SHELLSPEC_VERSION}/shellspec-dist.tar.gz" -o /tmp/shellspec.tar.gz \
    && echo "350d3de04ba61505c54eda31a3c2ee912700f1758b1a80a284bc08fd8b6c5992  /tmp/shellspec.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/local/lib/shellspec \
    && tar -xzf /tmp/shellspec.tar.gz -C /usr/local/lib/shellspec --strip-components=1 \
    && ln -s /usr/local/lib/shellspec/shellspec /usr/local/bin/shellspec \
    && rm /tmp/shellspec.tar.gz

# -----------------------------------------------------------------------------
# Layer 4: Collaboration tools
# -----------------------------------------------------------------------------
RUN case "${TARGETARCH}" in \
      amd64) arch=x86_64; sshx_version_id=XkaG41E86MM6KJLn5mogsBf3H54zuvmG; sshx_sha=faa53abd902f4391acbcba696c55052cd6553534bd4907305d4caca192430ef2; zellij_sha=397481870c4fc3bae646cd7613cde3a1cebdc204558a6cb9a7c603d4c852fc90 ;; \
      arm64) arch=aarch64; sshx_version_id=XoHUbtBswk6i0nYM1vXHEOvrYafEcr0f; sshx_sha=775d9a09aa7c770c5e6de5f2774b67f9df09155cdf86544d9d457f3f72e6701d; zellij_sha=439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0 ;; \
      *) exit 1 ;; \
    esac \
    && curl -fsSL "https://s3.amazonaws.com/sshx/sshx-${arch}-unknown-linux-musl.tar.gz?versionId=${sshx_version_id}" -o /tmp/sshx.tar.gz \
    && echo "${sshx_sha}  /tmp/sshx.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/sshx.tar.gz -C /tmp sshx \
    && install -m 0755 /tmp/sshx /usr/local/bin/sshx \
    && curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${arch}-unknown-linux-musl.tar.gz" -o /tmp/zellij.tar.gz \
    && tar -xzf /tmp/zellij.tar.gz -C /tmp zellij \
    && echo "${zellij_sha}  /tmp/zellij" | sha256sum -c - \
    && install -m 0755 /tmp/zellij /usr/local/bin/zellij \
    && rm -f /tmp/sshx.tar.gz /tmp/sshx /tmp/zellij.tar.gz /tmp/zellij

# -----------------------------------------------------------------------------
# Layer 5: Neovim terminal editor
# -----------------------------------------------------------------------------
RUN case "${TARGETARCH}" in \
      amd64) nvim_arch=x86_64; nvim_sha=31cf85945cb600d96cdf69f88bc68bec814acbff50863c5546adef3a1bcef260 ;; \
      arm64) nvim_arch=arm64; nvim_sha=f697d4e4582b6e4b5c3c26e76e06ce26efa08ba1768e03fd2733fcc422bb0490 ;; \
      *) exit 1 ;; \
    esac \
    && archive="nvim-linux-${nvim_arch}.tar.gz" \
    && curl -fsSL "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${archive}" -o "/tmp/${archive}" \
    && echo "${nvim_sha}  /tmp/${archive}" | sha256sum -c - \
    && tar -xzf "/tmp/${archive}" -C /opt \
    && ln -s "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim \
    && rm "/tmp/${archive}"

# -----------------------------------------------------------------------------
# Layer 6: Agent CLIs
# -----------------------------------------------------------------------------
RUN npm install -g --include=optional \
    "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    "@openai/codex@${CODEX_VERSION}" \
    "opencode-ai@${OPENCODE_VERSION}" \
    "@earendil-works/pi-coding-agent@${PI_VERSION}"

RUN case "${TARGETARCH}" in \
      amd64) agy_url=https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-x64/cli_linux_x64.tar.gz; agy_sha=1b57977be08398b0344ef5019089683c0aae9829545cdf3056c9a1d02b949ea98db6e643ef96ef4f6877654f4d48d5267035ef8a27652a8e023f65b91c06df76 ;; \
      arm64) agy_url=https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-arm/cli_linux_arm64.tar.gz; agy_sha=f9967fa8c318c31f78bcc2f813c754e0e6f7bac8030144561d5b303155720da8ca0485eca4b6c814299170526a1e8cc9dc9ec2091fccc1e9bdb864ddb9610757 ;; \
      *) exit 1 ;; \
    esac \
    && curl -fsSL "$agy_url" -o /tmp/agy.tar.gz \
    && echo "${agy_sha}  /tmp/agy.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/agy.tar.gz -C /tmp antigravity \
    && install -m 0755 /tmp/antigravity /usr/local/bin/agy \
    && rm -f /tmp/agy.tar.gz /tmp/antigravity

# -----------------------------------------------------------------------------
# Layer 7: Paperclip agent-orchestration platform
# -----------------------------------------------------------------------------
# Installed globally and run as a background service inside this container by
# .devcontainer/start-paperclip.bash (trusted local loopback, no login).
# Embedded PostgreSQL binaries are fetched on first run under PAPERCLIP_HOME.
#
# embedded-postgres also creates shared-library symlinks (e.g. libcrypto) INSIDE
# its own package directory on first start. The server runs as the vscode user,
# but `npm install -g` writes the tree as root, so chown it to vscode -- without
# this, embedded PostgreSQL fails with EACCES creating those symlinks.
RUN npm install -g "paperclipai@${PAPERCLIP_VERSION}" \
    && chown -R vscode:vscode /usr/local/lib/node_modules/paperclipai

# -----------------------------------------------------------------------------
# Layer 8: Environment and workspace defaults
# -----------------------------------------------------------------------------
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    AGENTIC_BUSINESS_OS_DEVCONTAINER=1 \
    AGY_CLI_DISABLE_AUTO_UPDATE=true \
    DISABLE_AUTOUPDATER=1

WORKDIR /workspaces/agentic-business-os
USER vscode
