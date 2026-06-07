# agentic-business-os Development Container

This environment supports GitHub Codespaces and other Dev Container clients on Linux amd64 and arm64.

It mirrors the `lean-software-production/workshops` devcontainer, with one addition: a
[Paperclip](https://github.com/paperclipai/paperclip) instance runs automatically inside the
container (see [Paperclip](#paperclip) below).

## Included Tools

- Node.js 22 and Python 3
- Claude Code, Codex, OpenCode, Pi, and Antigravity (`agy`)
- Paperclip agent-orchestration platform (`paperclipai`), running on port 3100
- GitHub CLI, Live Share, `sshx`, and `zellij`
- Neovim with a minimal LazyVim fallback
- ShellCheck and ShellSpec

## Paperclip

Paperclip is bundled directly into this dev container and started automatically by the
`postStartCommand` (`.devcontainer/start-paperclip.bash`). It runs in **trusted local loopback
mode with no login required**, serving its UI and API on `http://127.0.0.1:3100`. Port 3100 is
forwarded, so the UI opens in your browser as soon as the Codespace is ready.

- **Storage**: with no `DATABASE_URL` set, Paperclip provisions an embedded PostgreSQL cluster
  on first start. The initial start downloads the PostgreSQL binaries and may take a minute.
- **Logs**: `$PAPERCLIP_HOME/paperclip.log`.
- **Restart**: re-run `.devcontainer/start-paperclip.bash` (idempotent — it no-ops if Paperclip
  is already running). To force a restart, stop the recorded pid in `$PAPERCLIP_HOME/paperclip.pid`
  first, or run `paperclipai run` in the foreground.
- **Driving agents**: Paperclip orchestrates agents using model providers. Add `ANTHROPIC_API_KEY`
  and/or `OPENAI_API_KEY` as Codespaces secrets (declared in `devcontainer.json`) so Paperclip can
  call those adapters.

> Trusted loopback mode is loopback-only by design. Because Paperclip runs inside the dev
> container (not as an independently networked service), Codespaces port-forwarding reaches it on
> the container's loopback without exposing it on the network.

### State persistence across restarts

All of Paperclip's durable state lives under `PAPERCLIP_HOME`, **not** only in Postgres. The layout
is `PAPERCLIP_HOME/instances/default/`:

| Path | Contents |
| --- | --- |
| `db/` | The embedded PostgreSQL data directory (the database itself) |
| `secrets/master.key` | Encryption key that decrypts secrets stored in the DB |
| `data/storage/` | Uploaded files / object storage |
| `data/backups/` | Automatic DB backups (hourly by default) |
| `config.json`, `.env` | Instance configuration |

`PAPERCLIP_HOME` is set in `devcontainer.json` (`containerEnv`) to
**`${containerWorkspaceFolder}/.paperclip-data`** — i.e. a git-ignored directory *inside* the
workspace folder. This is the one location that survives a **container rebuild** in both
environments:

- **Local VS Code Dev Containers**: only the project folder is bind-mounted into the container
  (`/workspaces/<repo>` ⇄ your host folder). A sibling like `/workspaces/.paperclip` would live in
  the container's ephemeral writable layer and be wiped on rebuild. Keeping the data *inside* the
  project folder means it lands on the host bind mount and persists.
- **Codespaces**: the whole `/workspaces` is a persistent volume, so this path persists across
  rebuilds there too.

It is git-ignored (`.gitignore` → `.paperclip-data/`) and excluded from VS Code's file
watcher/search, so the embedded PostgreSQL files never get committed or indexed.

Caveats:

- On **macOS/Windows**, the embedded PostgreSQL data dir runs on a Docker Desktop bind mount, whose
  fsync/permission behaviour can occasionally upset Postgres. If you hit DB corruption locally,
  switch `PAPERCLIP_HOME` to a named Docker volume instead.
- This does **not** survive *deleting* the Codespace (or `git clean -dfx` locally). To survive
  recreation, point `DATABASE_URL` at an external managed Postgres and separately persist
  `secrets/master.key` and `data/storage/` (or restore from `data/backups/`).

## First-Time Agent Setup

Add `OPENCODE_API_KEY` as a GitHub Codespaces secret before creating or rebuilding the Codespace. OpenCode and Pi read this variable directly; the repository does not write credential files.

Run:

```bash
.devcontainer/setup-agents.bash
```

Then authenticate individual tools:

```bash
claude       # use /login when prompted
codex login
agy          # follow the Google OAuth URL/code flow
gh auth status
```

## Pairing And Mobbing

- Start VS Code Live Share from the Live Share activity bar.
- Run `sshx` for a browser-accessible shared terminal.
- Run `zellij` for persistent terminal layouts.

Share terminal access only with intended participants and stop sharing when the session ends.

## Neovim And Personal Dotfiles

Run `nvim` to use Neovim. The post-create script installs the pinned LazyVim starter only when `~/.config/nvim` does not already exist.

GitHub Codespaces may automatically apply your personal dotfiles. Repository configuration cannot disable this. To use the shared LazyVim fallback, disable **Automatically install dotfiles** in your personal Codespaces settings before creating the Codespace, or ensure your dotfiles do not create `~/.config/nvim`.

## Tests

Run reduced host checks:

```bash
.devcontainer/test.bash
```

Build and fully test the current host architecture:

```bash
.devcontainer/build-and-test.bash
```

The local workflow does not emulate or test the other architecture.

## Codespaces Prebuilds

For an organization-owned repository, prebuilds require an eligible GitHub Team or Enterprise plan, a payment method, and a Codespaces spending limit. A repository administrator configures them under **Settings > Codespaces > Set up prebuild**:

- Branch: `main`
- Configuration: `.devcontainer/devcontainer.json`
- Trigger: every push
- Regions: only those used by participants
- Template history: one version initially
- Failure notifications: repository maintainers

Prebuilds capture image creation and the early lifecycle commands, but not user OAuth, the
post-create LazyVim fallback, or the post-start Paperclip launch.
