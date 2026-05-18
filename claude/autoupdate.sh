#!/usr/bin/env sh
# Sourced from the user's shell rc file by the claude-config installer.
# The installer writes CLAUDE_CONFIG_DIR (absolute path) into the rc line so
# this script works under any POSIX shell (bash, zsh, dash, ...) without
# needing to self-locate.

claude_config_autoupdate() {
  local _debug="${CLAUDE_AUTOUPDATE_DEBUG:-0}"
  _au_log() { [ "$_debug" = "1" ] && printf '[autoupdate] %s\n' "$*" >&2; }

  local config_dir
  config_dir="${CLAUDE_CONFIG_DIR:-}"
  _au_log "config_dir=$config_dir"
  if [ -z "$config_dir" ] || [ ! -d "$config_dir" ]; then
    _au_log "config_dir missing or not a directory — skipping"
    return 0
  fi

  # Only check once per day (use a stamp file)
  local stamp_file="$HOME/.claude/.autoupdate-stamp"
  local now
  now="$(date +%s)"
  if [ -f "$stamp_file" ]; then
    local last
    last="$(cat "$stamp_file" 2>/dev/null || echo 0)"
    local diff=$(( now - last ))
    _au_log "stamp age=${diff}s (threshold=86400)"
    # Skip if checked less than 24 hours ago
    if [ "$diff" -lt 86400 ]; then
      _au_log "checked recently — skipping"
      return 0
    fi
  fi

  if [ ! -d "$config_dir/.git" ]; then
    _au_log "no .git directory — skipping"
    return 0
  fi

  cd "$config_dir" || return
  _au_log "running git fetch..."
  # GIT_TERMINAL_PROMPT=0 prevents SSH passphrase prompts from blocking.
  # timeout 15 kills the fetch if the network stalls.
  GIT_TERMINAL_PROMPT=0 timeout 15 git fetch --quiet origin 2>/dev/null \
    || { _au_log "git fetch failed or timed out — skipping"; cd - >/dev/null; return; }
  _au_log "git fetch done"

  local local_head remote_head
  local_head="$(git rev-parse HEAD 2>/dev/null)"
  remote_head="$(git rev-parse @{u} 2>/dev/null || echo "")"

  if [ -n "$remote_head" ] && [ "$local_head" != "$remote_head" ]; then
    local new_commits
    new_commits="$(git log --oneline HEAD..@{u} 2>/dev/null)"
    local commit_count
    # printf avoids the trailing newline that makes `echo "" | wc -l` = 1.
    commit_count="$(printf '%s' "$new_commits" | wc -l)"

    echo ""
    echo "[claude-config] $commit_count update(s) available — auto-installing:"
    echo "$new_commits" | sed 's/^/  /'

    if git pull --ff-only --quiet 2>/dev/null; then
      echo "[claude-config] Reinstalling config..."
      bash "$config_dir/install.sh" --no-prompt
      echo "[claude-config] Done. Restart your shell to pick up changes."
      echo "$now" > "$stamp_file"
    else
      echo "[claude-config] Auto-update cancelled: local changes conflict with remote."
      echo "  Resolve manually: cd $config_dir && git pull && bash install.sh"
      # Don't stamp — retry next shell so the user keeps seeing the warning.
    fi
    echo ""
  else
    # Up to date — stamp so we don't fetch again for 24 hours.
    echo "$now" > "$stamp_file"
  fi
  cd - >/dev/null
}
claude_config_autoupdate
