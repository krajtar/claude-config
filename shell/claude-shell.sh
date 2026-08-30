# Claude Code shell integration
# Source this from ~/.bashrc or ~/.zshrc

# `c`: --fs shortcut + run-mode prompt when no args.
# Named `c`, not `claude` — it must never shadow the real `claude` binary, so
# plain `claude` invocations (muscle memory, scripts, other tools) always go
# straight to the actual command untouched.
# _CLAUDE_SHELL_C_DEFINED tracks whether *we* defined `c`, so re-sourcing this
# file doesn't mistake our own prior definition for a user collision.
if [[ -n "$_CLAUDE_SHELL_C_DEFINED" ]] || ! type c &>/dev/null; then
  c() {
    local args=()
    for arg in "$@"; do
      if [[ "$arg" == "--fs" ]]; then
        args+=("--fork-session")
      else
        args+=("$arg")
      fi
    done

    # When called with no args, ask where to run
    if [[ ${#args[@]} -eq 0 ]]; then
      echo "Run Claude:"
      echo "  1) Local (default)"
      echo "  2) Local + skip permissions"
      echo "  3) Local + Headroom proxy"
      echo "  4) Local + Headroom + skip permissions"
      printf "Choice [1]: "
      read -r choice
      case "${choice:-1}" in
        1) (unset ANTHROPIC_BASE_URL; claude --remote-control) ;;
        2) (unset ANTHROPIC_BASE_URL; claude --dangerously-skip-permissions --remote-control) ;;
        3)
          local proxy_pid=""
          if lsof -iTCP:8787 -sTCP:LISTEN &>/dev/null; then
            echo "Headroom proxy already running on :8787"
          else
            headroom proxy --port 8787 &>/dev/null &
            proxy_pid=$!
            sleep 1
          fi
          ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude --remote-control
          [[ -n "$proxy_pid" ]] && kill "$proxy_pid" 2>/dev/null
          ;;
        4)
          local proxy_pid=""
          if lsof -iTCP:8787 -sTCP:LISTEN &>/dev/null; then
            echo "Headroom proxy already running on :8787"
          else
            headroom proxy --port 8787 &>/dev/null &
            proxy_pid=$!
            sleep 1
          fi
          ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude --dangerously-skip-permissions --remote-control
          [[ -n "$proxy_pid" ]] && kill "$proxy_pid" 2>/dev/null
          ;;
        *) echo "Invalid choice."; return 1 ;;
      esac
    else
      (unset ANTHROPIC_BASE_URL; claude --remote-control "${args[@]}")
    fi
  }
  _CLAUDE_SHELL_C_DEFINED=1
else
  printf '⚠ claude-shell: c already defined (%s) — skipping function\n' \
    "$(type c 2>/dev/null | head -1)" >&2
fi

# `ch`/`cs`: plain shortcuts straight to the real `claude` binary — only set
# if the name isn't already taken by the user. Defining an alias that
# collides with a user function breaks re-sourcing their rc file: zsh errors
# "defining function based on alias" on the next parse.
_claude_shell_alias() {  # name, target
  local name="$1" target="$2" current
  # If it's already an alias pointing at our target (re-sourcing case), no-op.
  if [[ "$(type -t "$name" 2>/dev/null)" == "alias" ]]; then
    current="$(alias "$name" 2>/dev/null)"
    # bash prints: alias ch='claude --chrome'   zsh prints: ch='claude --chrome'
    if [[ "$current" == "alias $name='$target'" || "$current" == "$name='$target'" ]]; then
      return
    fi
  fi
  if type "$name" &>/dev/null; then
    printf '⚠ claude-shell: %s already defined (%s) — skipping alias\n' \
      "$name" "$(type "$name" 2>/dev/null | head -1)" >&2
    return
  fi
  alias "$name=$target"
}
_claude_shell_alias ch 'claude --chrome --remote-control'
_claude_shell_alias cs 'claude --dangerously-skip-permissions --remote-control'
unset -f _claude_shell_alias
