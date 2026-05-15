#!/bin/bash

# Stop hook: records timestamp of last Claude response and schedules sound alert.
# Sound fires ~4 min after response (1 min before 5-min cache expiry).

PID_FILE="/tmp/claude-cache-timer.pid"
TS_FILE="/tmp/claude-cache-timer.ts"

# Kill any existing sound timer
if [[ -f "$PID_FILE" ]]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null)
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

# Record current timestamp
date +%s > "$TS_FILE"

# Start fully detached sound timer (fires at 4 min = 240 s)
# disown + redirected I/O ensures the hook exits immediately
(sleep 240 && bash /Users/virt/.claude/scripts/cache-timer-play-sound.sh) </dev/null >/dev/null 2>&1 &
echo $! > "$PID_FILE"
disown

exit 0
