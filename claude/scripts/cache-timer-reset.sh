#!/bin/bash

# Stop hook: records timestamp of last Claude response and schedules sound alert.
# Sound fires ~59 min after response (1 min before 1h cache expiry).

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

# Start fully detached sound timer (fires at 59 min = 3540 s)
# disown + redirected I/O ensures the hook exits immediately
(sleep 3540 && bash /Users/virt/.claude/scripts/cache-timer-play-sound.sh) </dev/null >/dev/null 2>&1 &
echo $! > "$PID_FILE"
disown

exit 0
