#!/usr/bin/env bash
set -euo pipefail

# Play macOS system sounds in order, one per second.
# Stop with Ctrl+C.

SOUNDS=(
  "/System/Library/Sounds/Basso.aiff"
  "/System/Library/Sounds/Blow.aiff"
  "/System/Library/Sounds/Bottle.aiff"
  "/System/Library/Sounds/Frog.aiff"
  "/System/Library/Sounds/Funk.aiff"
  "/System/Library/Sounds/Glass.aiff"
  "/System/Library/Sounds/Hero.aiff"
  "/System/Library/Sounds/Morse.aiff"
  "/System/Library/Sounds/Ping.aiff"
  "/System/Library/Sounds/Pop.aiff"
  "/System/Library/Sounds/Purr.aiff"
  "/System/Library/Sounds/Sosumi.aiff"
  "/System/Library/Sounds/Submarine.aiff"
  "/System/Library/Sounds/Tink.aiff"
)

for f in "${SOUNDS[@]}"; do
  if [[ -f "$f" ]]; then
    echo "Playing: $(basename "$f")"
    afplay "$f" >/dev/null 2>&1 || true
    sleep 1
  else
    echo "Missing: $f"
  fi
done