#!/usr/bin/env bash
set -euo pipefail

# Works in both bash and zsh — but runs under bash via the shebang
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$HOME/projects"

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
mkdir -p "$PROJECTS_DIR"

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

# --- Add source line to shell rc files ---
add_source_line() {
  local rc_file="$1"
  local shell_name="$2"
  if [ -f "$rc_file" ]; then
    if ! grep -qF 'claude-shell.sh' "$rc_file" 2>/dev/null; then
      echo '' >> "$rc_file"
      echo '# Claude Code + SafeClaw' >> "$rc_file"
      echo '[ -f ~/.claude-shell.sh ] && . ~/.claude-shell.sh' >> "$rc_file"
      echo "✓ Added source line to $rc_file"
    else
      echo "✓ $rc_file already sources claude-shell.sh"
    fi
  else
    echo "⊘ $rc_file not found, skipping"
  fi
}

add_source_line "$HOME/.bashrc" "bash"
add_source_line "$HOME/.zshrc" "zsh"

# --- Clone claude-code-tips (provides dx plugin, statusline, hooks) ---
echo
TIPS_DIR="$PROJECTS_DIR/claude-code-tips"
if [ -d "$TIPS_DIR/.git" ]; then
  echo "✓ claude-code-tips already cloned at $TIPS_DIR"
  echo "  Pulling latest..."
  git -C "$TIPS_DIR" pull --ff-only 2>/dev/null || echo "  (pull skipped — may have local changes)"
else
  echo "Cloning claude-code-tips..."
  git clone https://github.com/ykdojo/claude-code-tips.git "$TIPS_DIR"
  echo "✓ Cloned claude-code-tips to $TIPS_DIR"
fi

# --- Install Claude Code plugins ---
echo
if command -v claude &>/dev/null; then
  echo "Installing plugins..."
  # claude plugin install superpowers@claude-plugins-official 2>/dev/null && echo "✓ Installed superpowers plugin" || echo "⊘ superpowers plugin already installed or failed"
  claude plugin install playwright@claude-plugins-official 2>/dev/null && echo "✓ Installed playwright plugin" || echo "⊘ playwright plugin already installed or failed"
  claude plugin install dx@ykdojo 2>/dev/null && echo "✓ Installed dx plugin" || echo "⊘ dx plugin already installed or failed"
else
  echo "⊘ claude CLI not found — install plugins manually after installing Claude Code:"
  echo "  claude plugin install superpowers@claude-plugins-official"
  echo "  claude plugin install playwright@claude-plugins-official"
  echo "  claude plugin install dx@ykdojo"
fi

echo
echo "=== Installation complete ==="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc  (or source ~/.zshrc)"
if ! command -v claude &>/dev/null; then
  echo "  2. Install Claude Code: npm install -g @anthropic-ai/claude-code"
  echo "  3. Run the installer again to set up plugins"
fi
