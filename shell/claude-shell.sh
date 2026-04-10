# Claude Code + SafeClaw shell integration
# Source this from ~/.bashrc or ~/.zshrc

SAFECLAW_DIR="$HOME/projects/safeclaw"

# Claude wrapper: --fs shortcut + container prompt when no args
claude() {
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
    local has_safeclaw=false
    [[ -d "$SAFECLAW_DIR/scripts" ]] && has_safeclaw=true

    echo "Run Claude:"
    echo "  1) Local (default)"
    echo "  2) Local + skip permissions"
    echo "  3) Local + Headroom proxy"
    echo "  4) Local + Headroom + skip permissions"
    if $has_safeclaw; then
      echo "  5) New SafeClaw container"
      echo "  6) New SafeClaw container + clone current repo"
    fi
    printf "Choice [1]: "
    read -r choice
    case "${choice:-1}" in
      1) command claude ;;
      2) command claude --dangerously-skip-permissions ;;
      3)
        local proxy_pid=""
        if lsof -iTCP:8787 -sTCP:LISTEN &>/dev/null; then
          echo "Headroom proxy already running on :8787"
        else
          headroom proxy --port 8787 &>/dev/null &
          proxy_pid=$!
          sleep 1
        fi
        ANTHROPIC_BASE_URL=http://127.0.0.1:8787 command claude
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
        ANTHROPIC_BASE_URL=http://127.0.0.1:8787 command claude --dangerously-skip-permissions
        [[ -n "$proxy_pid" ]] && kill "$proxy_pid" 2>/dev/null
        ;;
      5) $has_safeclaw && sc || { echo "SafeClaw not installed."; return 1; } ;;
      6) $has_safeclaw && scg || { echo "SafeClaw not installed."; return 1; } ;;
      *) echo "Invalid choice."; return 1 ;;
    esac
  else
    command claude "${args[@]}"
  fi
}

# Claude Code aliases — only set if the name isn't already taken by the user.
# Defining an alias that collides with a user function breaks re-sourcing their
# rc file: zsh errors "defining function based on alias" on the next parse.
type c  &>/dev/null || alias c='claude'
type ch &>/dev/null || alias ch='claude --chrome'
type cs &>/dev/null || alias cs='claude --dangerously-skip-permissions'

# Start the dashboard on port 7690
dashboard() {
  if lsof -iTCP:7690 -sTCP:LISTEN &>/dev/null; then
    echo "Dashboard already running on http://localhost:7690"
    return 0
  fi
  PORT=7690 npx nodemon "$SAFECLAW_DIR/dashboard/server.js"
}

# Start a new SafeClaw container (prompts for session name)
sc() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    printf "Session name (enter for random): "
    read -r name
    [[ -z "$name" ]] && name="s$(date +%s | tail -c 5)"
  fi
  "$SAFECLAW_DIR/scripts/run.sh" -s "$name" -n
}

# Start a new SafeClaw container and clone current repo into it
scg() {
  local remote
  remote=$(git remote get-url origin 2>/dev/null)
  if [[ -z "$remote" ]]; then
    echo "Error: not in a git repo or no 'origin' remote set."
    return 1
  fi
  # Extract owner/repo slug for gh repo clone (works with both SSH and HTTPS)
  local slug
  slug=$(echo "$remote" | sed -E 's#(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')
  local repo_name
  repo_name=$(basename "$PWD")
  local name="${1:-$repo_name}"
  "$SAFECLAW_DIR/scripts/run.sh" -s "$name" -n -g "$slug"
}
