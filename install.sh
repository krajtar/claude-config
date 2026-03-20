#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Configuration Installer ==="
echo "Source:  $SCRIPT_DIR"
echo "Target:  $CLAUDE_DIR"
echo

# --- Backup existing config ---
if [ -f "$CLAUDE_DIR/settings.json" ] || [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  BACKUP="$CLAUDE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
  echo "Backing up existing config to $BACKUP"
  mkdir -p "$BACKUP"
  [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$BACKUP/"
  [ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP/"
  [ -f "$CLAUDE_DIR/statusline-command.sh" ] && cp "$CLAUDE_DIR/statusline-command.sh" "$BACKUP/"
  echo
fi

# --- Ensure directories exist ---
mkdir -p "$CLAUDE_DIR/skills/k8s-force-cleanup"
mkdir -p "$CLAUDE_DIR/skills/k8s-list-ns-resources"

# --- Install CLAUDE.md ---
cp "$SCRIPT_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Installed CLAUDE.md"

# --- Install settings.json (replace __HOME__ placeholder) ---
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/claude/settings.json" > "$CLAUDE_DIR/settings.json"
echo "✓ Installed settings.json (paths adjusted for $HOME)"

# --- Install statusline script ---
cp "$SCRIPT_DIR/claude/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "✓ Installed statusline-command.sh"

# --- Install skills ---
cp "$SCRIPT_DIR/claude/skills/k8s-force-cleanup/SKILL.md" "$CLAUDE_DIR/skills/k8s-force-cleanup/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/k8s-list-ns-resources/SKILL.md" "$CLAUDE_DIR/skills/k8s-list-ns-resources/SKILL.md"
echo "✓ Installed custom skills"

# --- Install shell integration ---
cp "$SCRIPT_DIR/shell/claude-shell.sh" "$HOME/.claude-shell.sh"
echo "✓ Installed ~/.claude-shell.sh"

# Add source line to .bashrc if not already present
if ! grep -qF 'claude-shell.sh' "$HOME/.bashrc" 2>/dev/null; then
  echo '' >> "$HOME/.bashrc"
  echo '# Claude Code + SafeClaw' >> "$HOME/.bashrc"
  echo '[ -f ~/.claude-shell.sh ] && . ~/.claude-shell.sh' >> "$HOME/.bashrc"
  echo "✓ Added source line to ~/.bashrc"
else
  echo "✓ .bashrc already sources claude-shell.sh"
fi

echo
echo "=== Installation complete ==="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Install plugins:"
echo "     claude plugin install superpowers@claude-plugins-official"
echo "     claude plugin install playwright@claude-plugins-official"
echo "     claude plugin install dx@ykdojo"
echo "  3. If you use the statusline/hooks, clone claude-code-tips:"
echo "     git clone https://github.com/ykdojo/claude-code-tips.git ~/projects/claude-code-tips"
