# Claude Code Configuration

Personal Claude Code configuration, skills, aliases, and scripts — portable across machines. Works with both **bash** and **zsh** on **macOS**, **Linux**, and **Windows (WSL)**.

## What's included

| Path | Description |
|------|-------------|
| `claude/CLAUDE-base.md` | Shared preferences (git, security, problem solving, communication) |
| `claude/CLAUDE-macos.md` | macOS-specific additions (pbcopy, open, Homebrew) |
| `claude/CLAUDE-linux.md` | Linux-specific additions (xclip, xdg-open) |
| `claude/CLAUDE-windows.md` | Windows/WSL-specific additions (path translation, CRLF handling) |
| `claude/settings.json` | Settings (model, env vars, hooks, plugins, statusline) |
| `claude/statusline-command.sh` | Context/model display bar for statusline |
| `claude/skills/` | Custom skills (k8s-force-cleanup, k8s-list-ns-resources) |
| `claude/scripts/` | Statusline script, originally from [claude-code-tips](https://github.com/ykdojo/claude-code-tips) |
| `claude/plugins/cache-timer/` | Plugin that warns before the prompt cache expires (this repo is its marketplace) |
| `shell/claude-shell.sh` | Shell aliases and functions (c, ch, cs) |
| `install.sh` | Installer — copies config, installs plugins |

## Quick start

```bash
git clone git@github.com:krajtar/claude-config.git ~/claude-config
cd ~/claude-config && ./install.sh
```

The installer will:
1. **Detect your OS** (macOS / Linux / Windows via WSL) and install `CLAUDE.md` by concatenating the shared base with the OS-specific fragment
2. **Detect your shell** (bash or zsh) and only modify the appropriate rc file
3. Back up any existing `~/.claude` config
4. Install CLAUDE.md, settings.json, statusline script, and custom skills
5. Install shell aliases to `~/.claude-shell.sh` and source it from your rc file
6. **Ask if you want auto-updates** (see below)
7. Install plugins: `playwright`, `dx`

## Auto-updates

During installation you'll be prompted to enable auto-updates. If enabled, every new shell session (checked once per day) will:

1. Fetch the latest commits from the remote
2. If updates are available, show the list of new commits and ask whether to update
3. On confirmation, pull the changes, print what was downloaded, and reinstall the config

To disable auto-updates later, re-run `./install.sh` and answer **N** at the prompt — the updater block will be removed from your rc file.

### CLAUDE.md drift protection

The installer tracks a hash of the `CLAUDE.md` it installs. On subsequent updates:

- If you **haven't edited** `~/.claude/CLAUDE.md` — it gets updated automatically
- If you **have local edits** — the update is **skipped** with an error message to preserve your changes. You can diff against the new version and re-run the installer after resolving

## Cache freshness alert

The prompt cache invalidates after 1 hour of inactivity. To avoid silently paying for a cache miss, the `cache-timer` plugin (`claude/plugins/cache-timer/`) alerts ~55 minutes after the last main-conversation turn in each session:

- **Everywhere**: an in-app toast ("Prompt cache expires in ~5 min")
- **macOS**: Submarine sound + native notification banner
- **Linux**: completion sound via `paplay` / `aplay` (falls back to `beep`)
- Override the sound by exporting `CLAUDE_CACHE_SOUND=/path/to/file` (set to `/dev/null` to silence)
- Each session has its own timer; it resets on every turn, and subagent turns don't count
- The statusline shows the expiry time, read from `~/.claude/cache-timer/<session_id>.ts`, which the plugin writes

This repo is a local plugin marketplace (`.claude-plugin/marketplace.json`), so the plugin is read straight from the clone: after editing it, run `/reload-plugins`. Tests: `claude plugin test claude/plugins/cache-timer`.

## Plugins

Installed automatically by `install.sh` (`playwright`, `dx`, `cache-timer`). Manual install:

```
claude plugin install playwright@claude-plugins-official
claude plugin install dx@ykdojo
claude plugin marketplace add <path-to-this-repo> && claude plugin install cache-timer@claude-config
```

## Shell aliases

| Alias/Function | Description |
|----------------|-------------|
| `c` | Interactive menu: local / skip permissions / Headroom proxy / Headroom + skip permissions |
| `ch` | `claude --chrome --remote-control` |
| `cs` | `claude --dangerously-skip-permissions --remote-control` |

`claude` itself is never shadowed — it always runs the real binary untouched.

## Dependencies

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- [Headroom](https://github.com/chopratejas/headroom) (optional — context compression proxy, used by the `c` interactive menu)
- `jq`, `python3` (for statusline script)

The statusline script under `claude/scripts/` was originally vendored from [claude-code-tips](https://github.com/ykdojo/claude-code-tips). The `dx@ykdojo` plugin still resolves via Claude Code's marketplace system (no local clone needed).
