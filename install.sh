#!/usr/bin/env bash
set -euo pipefail

# Works in both bash and zsh — but runs under bash via the shebang
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$HOME/projects"

NO_PROMPT=false
if [[ "${1:-}" == "--no-prompt" ]]; then
  NO_PROMPT=true
fi

echo "=== Claude Code Configuration Installer ==="
echo "Source:  $SCRIPT_DIR"
echo "Target:  $CLAUDE_DIR"
echo

# --- Detect OS ---
detect_os() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)
      # Check if running under WSL
      if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
        echo "windows"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "windows"
      ;;
    *)
      echo "linux"  # default fallback
      ;;
  esac
}

DETECTED_OS="$(detect_os)"
echo "Detected OS: $DETECTED_OS"
echo

# --- Detect user's shell ---
detect_user_shell() {
  local user_shell
  user_shell="$(basename "${SHELL:-/bin/bash}")"
  case "$user_shell" in
    zsh)  echo "zsh" ;;
    bash) echo "bash" ;;
    *)    echo "bash" ;;  # fallback
  esac
}

USER_SHELL="$(detect_user_shell)"
case "$USER_SHELL" in
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  bash) RC_FILE="$HOME/.bashrc" ;;
esac
echo "Detected shell: $USER_SHELL (rc file: $RC_FILE)"
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
mkdir -p "$CLAUDE_DIR/skills/verify"
mkdir -p "$CLAUDE_DIR/skills/commits"
mkdir -p "$CLAUDE_DIR/skills/debug"
mkdir -p "$CLAUDE_DIR/skills/explore"
mkdir -p "$CLAUDE_DIR/skills/dispatch"
mkdir -p "$CLAUDE_DIR/skills/review"
mkdir -p "$CLAUDE_DIR/skills/tdd"
mkdir -p "$CLAUDE_DIR/skills/plan"
mkdir -p "$CLAUDE_DIR/skills/dev"
mkdir -p "$CLAUDE_DIR/skills/oneshot"
mkdir -p "$PROJECTS_DIR"

# --- Install CLAUDE.md: base + OS-specific (with drift detection) ---
CLAUDE_BASE="$SCRIPT_DIR/claude/CLAUDE-base.md"
CLAUDE_OS="$SCRIPT_DIR/claude/CLAUDE-${DETECTED_OS}.md"

HASH_FILE="$CLAUDE_DIR/.claude-md-hash"
CLAUDE_MD_DST="$CLAUDE_DIR/CLAUDE.md"

install_claude_md() {
  # Concatenate base + OS-specific fragment
  cat "$CLAUDE_BASE" > "$CLAUDE_MD_DST"
  if [ -f "$CLAUDE_OS" ]; then
    cat "$CLAUDE_OS" >> "$CLAUDE_MD_DST"
  fi
  # Store hash of what we installed so we can detect user edits later
  shasum -a 256 "$CLAUDE_MD_DST" | awk '{print $1}' > "$HASH_FILE"
}

if [ ! -f "$CLAUDE_MD_DST" ]; then
  # Fresh install — no existing file
  install_claude_md
  echo "✓ Installed CLAUDE.md ($DETECTED_OS variant)"
elif [ ! -f "$HASH_FILE" ]; then
  # Existing file but no hash — migrating from before drift detection.
  # Build what we would install into a temp file and compare
  tmp_expected="$(mktemp)"
  cat "$CLAUDE_BASE" > "$tmp_expected"
  [ -f "$CLAUDE_OS" ] && cat "$CLAUDE_OS" >> "$tmp_expected"
  src_hash="$(shasum -a 256 "$tmp_expected" | awk '{print $1}')"
  rm -f "$tmp_expected"
  dst_hash="$(shasum -a 256 "$CLAUDE_MD_DST" | awk '{print $1}')"
  if [ "$src_hash" = "$dst_hash" ]; then
    install_claude_md
    echo "✓ Installed CLAUDE.md ($DETECTED_OS variant)"
  else
    echo "⚠ ERROR: ~/.claude/CLAUDE.md has local modifications (no prior hash found)"
    echo "  Skipping CLAUDE.md update to preserve your changes."
    echo "  To accept the new version, delete ~/.claude/CLAUDE.md and re-run the installer."
  fi
else
  # Hash file exists — compare to detect drift
  stored_hash="$(cat "$HASH_FILE")"
  current_hash="$(shasum -a 256 "$CLAUDE_MD_DST" | awk '{print $1}')"
  if [ "$stored_hash" = "$current_hash" ]; then
    # User hasn't modified it — safe to overwrite
    install_claude_md
    echo "✓ Installed CLAUDE.md ($DETECTED_OS variant)"
  else
    echo "⚠ ERROR: ~/.claude/CLAUDE.md has local modifications that conflict with the update"
    echo "  Skipping CLAUDE.md update to preserve your changes."
    echo "  To see what changed upstream: diff ~/.claude/CLAUDE.md $CLAUDE_MD_SRC"
    echo "  To accept the new version, delete ~/.claude/CLAUDE.md and re-run the installer."
  fi
fi

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
cp "$SCRIPT_DIR/claude/skills/verify/SKILL.md" "$CLAUDE_DIR/skills/verify/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/commits/SKILL.md" "$CLAUDE_DIR/skills/commits/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/debug/SKILL.md" "$CLAUDE_DIR/skills/debug/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/explore/SKILL.md" "$CLAUDE_DIR/skills/explore/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/dispatch/SKILL.md" "$CLAUDE_DIR/skills/dispatch/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/review/SKILL.md" "$CLAUDE_DIR/skills/review/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/tdd/SKILL.md" "$CLAUDE_DIR/skills/tdd/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/plan/SKILL.md" "$CLAUDE_DIR/skills/plan/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/dev/SKILL.md" "$CLAUDE_DIR/skills/dev/SKILL.md"
cp "$SCRIPT_DIR/claude/skills/oneshot/SKILL.md" "$CLAUDE_DIR/skills/oneshot/SKILL.md"
echo "✓ Installed custom skills"

# --- Install shell integration ---
cp "$SCRIPT_DIR/shell/claude-shell.sh" "$HOME/.claude-shell.sh"
echo "✓ Installed ~/.claude-shell.sh"

# --- Add source line to the user's shell rc file ---
add_source_line() {
  local rc_file="$1"
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
    # Create the rc file if it doesn't exist
    echo '# Claude Code + SafeClaw' > "$rc_file"
    echo '[ -f ~/.claude-shell.sh ] && . ~/.claude-shell.sh' >> "$rc_file"
    echo "✓ Created $rc_file with source line"
  fi
}

add_source_line "$RC_FILE"

# --- Autoupdate prompt (skip in non-interactive mode) ---
if [[ "$NO_PROMPT" == true ]]; then
  echo
  echo "=== Auto-update reinstall complete ==="
  exit 0
fi

echo
if ! [[ -e "$HOME/.claude/.autoupdate-stamp" ]]; then
  read -rp "Enable auto-updates for claude-config on shell startup? (y/N): " ENABLE_AUTOUPDATE
fi

if [[ "$ENABLE_AUTOUPDATE" == [yY] || "$ENABLE_AUTOUPDATE" == [yY][eE][sS] ]]; then
  AUTOUPDATE_BLOCK='
# Claude Config auto-update
claude_config_autoupdate() {
  local config_dir="'"$SCRIPT_DIR"'"
  # Only check once per day (use a stamp file)
  local stamp_file="$HOME/.claude/.autoupdate-stamp"
  local now
  now="$(date +%s)"
  if [ -f "$stamp_file" ]; then
    local last
    last="$(cat "$stamp_file" 2>/dev/null || echo 0)"
    local diff=$(( now - last ))
    # Skip if checked less than 24 hours ago
    if [ "$diff" -lt 86400 ]; then
      return 0
    fi
  fi

  if [ ! -d "$config_dir/.git" ]; then
    return 0
  fi

  cd "$config_dir" || return
  git fetch --quiet origin 2>/dev/null || { cd - >/dev/null; return; }

  local local_head remote_head
  local_head="$(git rev-parse HEAD 2>/dev/null)"
  remote_head="$(git rev-parse @{u} 2>/dev/null || echo "")"

  # Update stamp regardless of whether there are updates
  echo "$now" > "$stamp_file"

  if [ -n "$remote_head" ] && [ "$local_head" != "$remote_head" ]; then
    local new_commits
    new_commits="$(git log --oneline HEAD..@{u} 2>/dev/null)"
    local commit_count
    commit_count="$(echo "$new_commits" | wc -l | tr -d " ")"

    echo ""
    echo "[claude-config] $commit_count new update(s) available:"
    echo "$new_commits"
    echo ""
    printf "Do you want to update now? (y/N): "
    read -r answer </dev/tty
    if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
      local old_head="$local_head"
      if git pull --ff-only --quiet 2>/dev/null; then
        echo ""
        echo "[claude-config] Updated! Commits pulled:"
        git log --oneline "$old_head"..HEAD
        echo ""
        echo "[claude-config] Reinstalling config..."
        bash "$config_dir/install.sh" --no-prompt
        echo "[claude-config] Done. Restart your shell to pick up any new changes."
      else
        echo "[claude-config] Pull failed (you may have local changes). Run manually:"
        echo "  cd $config_dir && git pull && bash install.sh"
      fi
    else
      echo "[claude-config] Skipped. Run the installer manually when ready."
    fi
  fi
  cd - >/dev/null
}
claude_config_autoupdate'

  # Add autoupdate block to rc file
  if ! grep -qF 'claude_config_autoupdate' "$RC_FILE" 2>/dev/null; then
    echo "$AUTOUPDATE_BLOCK" >> "$RC_FILE"
    echo "✓ Added auto-update to $RC_FILE (checks daily on shell startup)"
  else
    echo "✓ Auto-update already configured in $RC_FILE"
  fi
else
  # Remove autoupdate block if it exists (user opted out)
  if grep -qF 'claude_config_autoupdate' "$RC_FILE" 2>/dev/null; then
    # Remove the autoupdate block
    sed -i.bak '/# Claude Config auto-update/,/^claude_config_autoupdate$/d' "$RC_FILE"
    rm -f "${RC_FILE}.bak"
    echo "✓ Removed auto-update from $RC_FILE"
  else
    echo "✓ Auto-update not enabled"
  fi
fi

# --- Clone claude-code-tips (provides dx plugin, statusline, hooks) ---
echo
TIPS_DIR="$PROJECTS_DIR/claude-code-tips"
if [ -d "$TIPS_DIR/.git" ]; then
  echo "✓ claude-code-tips already cloned at $TIPS_DIR"
  echo "  Pulling latest..."
  git -C "$TIPS_DIR" pull --ff-only --quiet 2>/dev/null || echo "  (pull skipped — may have local changes)"
else
  echo "Cloning claude-code-tips..."
  git clone https://github.com/ykdojo/claude-code-tips.git "$TIPS_DIR"
  echo "✓ Cloned claude-code-tips to $TIPS_DIR"
fi

# --- Install Claude Code plugins ---
echo
if command -v claude &>/dev/null; then
  echo "Installing plugins..."
  _install_plugin() {
    local pkg="$1" label="$2"
    local err
    err=$(claude plugin install "$pkg" 2>&1 >/dev/null)
    if [ $? -eq 0 ]; then
      echo "✓ Installed $label"
    elif echo "$err" | grep -qi "already"; then
      echo "✓ $label already installed"
    else
      echo "⊘ Failed to install $label"
      [ -n "$err" ] && echo "  $err"
    fi
  }
  _install_plugin playwright@claude-plugins-official "playwright plugin"
  _install_plugin dx@ykdojo "dx plugin"
else
  echo "⊘ claude CLI not found — install plugins manually after installing Claude Code:"
  echo "  claude plugin install playwright@claude-plugins-official"
  echo "  claude plugin install dx@ykdojo"
fi

echo
echo "=== Installation complete ==="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: source $RC_FILE"
if ! command -v claude &>/dev/null; then
  echo "  2. Install Claude Code: npm install -g @anthropic-ai/claude-code"
  echo "  3. Run the installer again to set up plugins"
fi
