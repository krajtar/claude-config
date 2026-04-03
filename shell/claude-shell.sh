# Claude Code + SafeClaw shell integration
# Source this from ~/.bashrc or ~/.zshrc

SAFECLAW_DIR="$HOME/projects/safeclaw"

# Claude Code aliases
alias c='claude'
alias ch='claude --chrome'
alias cs='claude --dangerously-skip-permissions'

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
    echo "Run Claude:"
    echo "  1) Local (default)"
    echo "  2) Local + Headroom proxy"
    echo "  3) New SafeClaw container"
    echo "  4) New SafeClaw container + clone current repo"
    printf "Choice [1]: "
    read -r choice
    case "${choice:-1}" in
      1) command claude ;;
      2)
        headroom proxy --port 8787 &>/dev/null &
        local proxy_pid=$!
        # Wait briefly for proxy to start
        sleep 1
        ANTHROPIC_BASE_URL=http://127.0.0.1:8787 command claude
        kill "$proxy_pid" 2>/dev/null
        ;;
      3) sc ;;
      4) scg ;;
      *) echo "Invalid choice."; return 1 ;;
    esac
  else
    command claude "${args[@]}"
  fi
}

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
