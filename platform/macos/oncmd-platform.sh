#!/usr/bin/env bash
# OnCmd native macOS power/session adapter.
set -euo pipefail

case "${1:-status}" in
  lock)
    /usr/bin/osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
    ;;
  sleep)
    /usr/bin/pmset sleepnow
    ;;
  status)
    printf 'platform=macOS\n'
    printf 'lock=osascript/System Events\n'
    printf 'sleep=pmset sleepnow\n'
    ;;
  *)
    printf 'Usage: %s {status|lock|sleep}\n' "$0" >&2
    exit 2
    ;;
esac
