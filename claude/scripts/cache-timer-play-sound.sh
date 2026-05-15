#!/bin/bash

# Cross-platform sound player for cache-timer alert.
# Override sound file via CLAUDE_CACHE_SOUND env var.

PLATFORM=$(uname)

play_sound() {
    local file="$1"
    case "$PLATFORM" in
        Darwin) afplay "$file" 2>/dev/null ;;
        Linux)
            if command -v paplay &>/dev/null; then
                paplay "$file" 2>/dev/null
            elif command -v aplay &>/dev/null; then
                aplay "$file" 2>/dev/null
            fi
            ;;
    esac
}

if [[ -n "$CLAUDE_CACHE_SOUND" ]]; then
    play_sound "$CLAUDE_CACHE_SOUND"
elif [[ "$PLATFORM" == "Darwin" ]]; then
    afplay /System/Library/Sounds/Submarine.aiff 2>/dev/null
elif [[ "$PLATFORM" == "Linux" ]]; then
    DEFAULT_SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"
    if command -v paplay &>/dev/null; then
        paplay "$DEFAULT_SOUND" 2>/dev/null
    elif command -v aplay &>/dev/null; then
        aplay "$DEFAULT_SOUND" 2>/dev/null
    elif command -v beep &>/dev/null; then
        beep 2>/dev/null
    fi
fi

exit 0
