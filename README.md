# Claude Code Configuration

Personal Claude Code configuration, skills, aliases, and scripts — portable across machines.

## What's included

| Path | Description |
|------|-------------|
| `claude/CLAUDE.md` | Global preferences (git, security, WSL, communication style) |
| `claude/settings.json` | Settings (model, env vars, hooks, plugins, statusline) |
| `claude/statusline-command.sh` | Context/model display bar for statusline |
| `claude/skills/` | Custom skills (k8s-force-cleanup, k8s-list-ns-resources) |
| `shell/claude-shell.sh` | Shell aliases and functions (c, ch, cs, sc, scg, dashboard) |
| `install.sh` | Installer script — symlinks everything into place |

## Quick start

```bash
git clone git@github.com:krajtar/claude-config.git ~/claude-config
cd ~/claude-config
./install.sh
```

## Plugins

Plugins are installed via Claude Code's plugin system, not tracked here. After install, run:

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
