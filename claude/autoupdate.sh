#!/usr/bin/env sh
# Sourced from the user's shell rc file by the claude-config installer.
# The installer writes CLAUDE_CONFIG_DIR (absolute path) into the rc line so
# this script works under any POSIX shell (bash, zsh, dash, ...) without
# needing to self-locate.

claude_config_autoupdate() {
  local config_dir
  config_dir="${CLAUDE_CONFIG_DIR:-}"
  if [ -z "$config_dir" ] || [ ! -d "$config_dir" ]; then
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
    case "$answer" in
      [yY]|[yY][eE][sS]) answer_yes=1 ;;
      *) answer_yes=0 ;;
    esac
    if [ "$answer_yes" = 1 ]; then
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
claude_config_autoupdate
