#!/usr/bin/env bash
set -euo pipefail

# Works in both bash and zsh — but runs under bash via the shebang
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

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
  [ -f "$CLAUDE_DIR/CLAUDE-managed.md" ] && cp "$CLAUDE_DIR/CLAUDE-managed.md" "$BACKUP/"
  [ -f "$CLAUDE_DIR/statusline-command.sh" ] && cp "$CLAUDE_DIR/statusline-command.sh" "$BACKUP/"
  echo
fi

# --- Skill list (single source of truth for mkdir + cp loops below) ---
SKILLS=(
  k8s-force-cleanup
  k8s-list-ns-resources
  verify
  commits
  diagnose
  explore
  dispatch
  review
  tdd
  plan
  dev
  oneshot
)

# --- Ensure directories exist ---
for skill in "${SKILLS[@]}"; do
  mkdir -p "$CLAUDE_DIR/skills/$skill"
done
mkdir -p "$CLAUDE_DIR/scripts"

# --- Install CLAUDE.md (layered: managed + personal) ---
#
# Layout:
#   ~/.claude/CLAUDE-managed.md  — base + OS fragment, overwritten every install.
#   ~/.claude/CLAUDE.md          — user's personal file. Installer only ever
#                                  creates it (once) and ensures the @import
#                                  line is present on the first line. All other
#                                  edits belong to the user.
#
# The hash file tracks CLAUDE-managed.md so we can detect (for diagnostics) if
# someone has hand-edited it; CLAUDE.md itself is never drift-checked because
# it's owned by the user.
CLAUDE_BASE="$SCRIPT_DIR/claude/CLAUDE-base.md"
CLAUDE_OS="$SCRIPT_DIR/claude/CLAUDE-${DETECTED_OS}.md"

MANAGED_DST="$CLAUDE_DIR/CLAUDE-managed.md"
USER_DST="$CLAUDE_DIR/CLAUDE.md"
HASH_FILE="$CLAUDE_DIR/.claude-md-hash"
IMPORT_LINE='@~/.claude/CLAUDE-managed.md'

write_managed() {
  cat "$CLAUDE_BASE" > "$MANAGED_DST"
  [ -f "$CLAUDE_OS" ] && cat "$CLAUDE_OS" >> "$MANAGED_DST"
  shasum -a 256 "$MANAGED_DST" | awk '{print $1}' > "$HASH_FILE"
}

write_user_stub() {
  cat > "$USER_DST" <<EOF
$IMPORT_LINE

<!-- The line above imports shared rules managed by claude-config.
     Leave it in place — the installer will re-add it if removed.
     Add your personal global rules below. -->
EOF
}

# Idempotently ensure the @import line is present in CLAUDE.md.
# Prepends it if missing — no warning, just fixes it.
ensure_import_line() {
  if ! grep -qxF "$IMPORT_LINE" "$USER_DST" 2>/dev/null; then
    local tmp
    tmp="$(mktemp)"
    printf '%s\n\n' "$IMPORT_LINE" > "$tmp"
    cat "$USER_DST" >> "$tmp"
    mv "$tmp" "$USER_DST"
    echo "✓ Re-added missing @import line to ~/.claude/CLAUDE.md"
  fi
}

# Strip any line from CLAUDE.md that also appears verbatim in CLAUDE-managed.md.
# Empty lines are excluded from the strip set (every doc has blanks — an empty
# pattern line would make grep -Fx match every blank line in the target). Runs
# of 2+ blank lines left behind are collapsed into a single blank line so
# stripped sections don't leave visible gaps.
dedupe_user_from_managed() {
  [ -f "$MANAGED_DST" ] || return 0
  local patterns stripped_tmp before after stripped
  patterns="$(mktemp)"
  stripped_tmp="$(mktemp)"
  grep -v '^$' "$MANAGED_DST" > "$patterns" || true

  before="$(wc -l < "$USER_DST")"
  grep -vxFf "$patterns" "$USER_DST" > "$stripped_tmp" || true
  after="$(wc -l < "$stripped_tmp")"
  stripped=$(( before - after ))

  if [ "$stripped" -gt 0 ]; then
    # Collapse runs of blank lines left behind into a single blank line.
    awk 'BEGIN{blank=0} /^$/{blank++; if(blank<=1) print; next} {blank=0; print}' \
      "$stripped_tmp" > "$USER_DST"
    echo "✓ Removed $stripped duplicated managed line(s) from ~/.claude/CLAUDE.md"
  fi
  rm -f "$patterns" "$stripped_tmp"
}

if [ ! -f "$USER_DST" ]; then
  # Fresh install — no CLAUDE.md at all.
  write_managed
  write_user_stub
  echo "✓ Installed CLAUDE-managed.md ($DETECTED_OS variant)"
  echo "✓ Created ~/.claude/CLAUDE.md (personal file with @import)"
elif [ ! -f "$MANAGED_DST" ]; then
  # TODO(2026-07): delete this migration block once users are on the layered
  # layout. When this branch is removed, the if/elif/else collapses into just
  # the fresh-install and normal-update paths.
  # Migration from the old single-file layout. The existing CLAUDE.md used to
  # be the managed file; figure out whether it's clean (safe to replace with a
  # fresh stub) or has user edits (preserve it, just prepend the import).
  if [ -f "$HASH_FILE" ]; then
    stored_hash="$(cat "$HASH_FILE")"
    current_hash="$(shasum -a 256 "$USER_DST" | awk '{print $1}')"
    if [ "$stored_hash" = "$current_hash" ]; then
      # Clean old install: CLAUDE.md matches exactly what the old installer
      # wrote. Replace it with a fresh personal stub.
      write_managed
      write_user_stub
      echo "✓ Migrated to layered CLAUDE.md (managed + personal)"
    else
      # Old install with user edits. Preserve CLAUDE.md, write managed alongside,
      # prepend @import, and strip any lines that duplicate the managed content.
      write_managed
      ensure_import_line
      dedupe_user_from_managed
      echo "✓ Migrated to layered CLAUDE.md ($DETECTED_OS variant)"
    fi
  else
    # No hash file at all — very old install. Preserve, prepend import, dedupe.
    write_managed
    ensure_import_line
    dedupe_user_from_managed
    echo "✓ Migrated to layered CLAUDE.md ($DETECTED_OS variant)"
  fi
else
  # Normal update path: both files already exist in the new layout.
  write_managed
  ensure_import_line
  dedupe_user_from_managed
  echo "✓ Updated CLAUDE-managed.md ($DETECTED_OS variant)"
fi

# --- Install settings.json (replace __HOME__ placeholder) ---
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/claude/settings.json" > "$CLAUDE_DIR/settings.json"
echo "✓ Installed settings.json (paths adjusted for $HOME)"

# --- Install statusline script ---
cp "$SCRIPT_DIR/claude/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "✓ Installed statusline-command.sh"

# --- Install skills ---
for skill in "${SKILLS[@]}"; do
  cp "$SCRIPT_DIR/claude/skills/$skill/SKILL.md" "$CLAUDE_DIR/skills/$skill/SKILL.md"
done
echo "✓ Installed custom skills"

# --- Install vendored scripts (statusline + context check hook) ---
# These are vendored from https://github.com/ykdojo/claude-code-tips — see
# claude/scripts/*.sh headers. Sync manually if upstream changes.
cp "$SCRIPT_DIR/claude/scripts/check-context.sh" "$CLAUDE_DIR/scripts/check-context.sh"
cp "$SCRIPT_DIR/claude/scripts/context-bar.sh" "$CLAUDE_DIR/scripts/context-bar.sh"
chmod +x "$CLAUDE_DIR/scripts/check-context.sh" "$CLAUDE_DIR/scripts/context-bar.sh"
echo "✓ Installed vendored scripts (check-context.sh, context-bar.sh)"

# --- Install shell integration ---
# Symlink so edits in the repo take effect immediately (no re-install needed)
ln -sfn "$SCRIPT_DIR/shell/claude-shell.sh" "$HOME/.claude-shell.sh"
echo "✓ Linked ~/.claude-shell.sh → $SCRIPT_DIR/shell/claude-shell.sh"

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
ENABLE_AUTOUPDATE=""
if ! grep -qF 'claude_config_autoupdate' "$RC_FILE" 2>/dev/null; then
  read -rp "Enable auto-updates for claude-config on shell startup? (y/N): " ENABLE_AUTOUPDATE
fi

if [[ "$ENABLE_AUTOUPDATE" == [yY] || "$ENABLE_AUTOUPDATE" == [yY][eE][sS] ]]; then
  # Add autoupdate block to rc file (source lives in claude/autoupdate.sh;
  # __CONFIG_DIR__ placeholder gets replaced with the absolute config path).
  if ! grep -qF 'claude_config_autoupdate' "$RC_FILE" 2>/dev/null; then
    sed "s|__CONFIG_DIR__|$SCRIPT_DIR|g" "$SCRIPT_DIR/claude/autoupdate.sh" >> "$RC_FILE"
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
