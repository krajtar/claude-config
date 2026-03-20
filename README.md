# Claude Code Configuration

Personal Claude Code configuration, skills, aliases, and scripts — portable across machines. Works with both **bash** and **zsh**.

## What's included

| Path | Description |
|------|-------------|
| `claude/CLAUDE.md` | Global preferences (git, security, WSL, communication style) |
| `claude/settings.json` | Settings (model, env vars, hooks, plugins, statusline) |
| `claude/statusline-command.sh` | Context/model display bar for statusline |
| `claude/skills/` | Custom skills (k8s-force-cleanup, k8s-list-ns-resources) |
| `shell/claude-shell.sh` | Shell aliases and functions (c, ch, cs, sc, scg, dashboard) |
| `install.sh` | Installer — copies config, clones dependencies, installs plugins |

## Quick start

```bash
git clone git@github.com:krajtar/claude-config.git ~/claude-config
cd ~/claude-config && ./install.sh
```

The installer will:
1. Back up any existing `~/.claude` config
2. Install CLAUDE.md, settings.json, statusline script, and custom skills
3. Install shell aliases to `~/.claude-shell.sh` and source it from both `~/.bashrc` and `~/.zshrc`
4. Clone [claude-code-tips](https://github.com/ykdojo/claude-code-tips) to `~/projects/claude-code-tips` (provides dx plugin, statusline scripts, hooks)
5. Install plugins: `superpowers`, `playwright`, `dx`

## Plugins

Installed automatically by `install.sh`. Manual install:

```
claude plugin install superpowers@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install dx@ykdojo
```

## Shell aliases

| Alias/Function | Description |
|----------------|-------------|
| `c` | `claude` |
| `ch` | `claude --chrome` |
| `cs` | `claude --dangerously-skip-permissions` |
| `claude` (no args) | Interactive menu: local / SafeClaw container / SafeClaw + repo clone |
| `sc [name]` | Start SafeClaw container |
| `scg [name]` | Start SafeClaw container + clone current repo |
| `dashboard` | Start SafeClaw dashboard on port 7690 |

## Dependencies

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- [claude-code-tips](https://github.com/ykdojo/claude-code-tips) (cloned automatically)
- `jq`, `python3` (for statusline script)
