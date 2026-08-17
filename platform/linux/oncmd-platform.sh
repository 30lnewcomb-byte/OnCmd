#!/usr/bin/env bash
# OnCmd native Linux power/session adapter.
# Prefers systemd/logind, with common desktop fallbacks for locking.
set -euo pipefail

lock_session() {
  if command -v loginctl >/dev/null 2>&1 && loginctl lock-session; then return 0; fi
  if command -v xdg-screensaver >/dev/null 2>&1 && xdg-screensaver lock; then return 0; fi
  if command -v gnome-screensaver-command >/dev/null 2>&1 && gnome-screensaver-command -l; then return 0; fi
  printf '%s\n' 'No supported Linux session-lock command was found.' >&2
  return 1
}

sleep_system() {
  if command -v systemctl >/dev/null 2>&1 && systemctl suspend; then return 0; fi
  if command -v loginctl >/dev/null 2>&1 && loginctl suspend; then return 0; fi
  printf '%s\n' 'No supported Linux suspend command was found.' >&2
  return 1
}

case "${1:-status}" in
  lock) lock_session ;;
  sleep) sleep_system ;;
  status)
    printf 'platform=Linux\n'
    command -v loginctl >/dev/null 2>&1 && printf 'logind=available\n' || printf 'logind=unavailable\n'
    command -v systemctl >/dev/null 2>&1 && printf 'systemd=available\n' || printf 'systemd=unavailable\n'
    ;;
  *)
    printf 'Usage: %s {status|lock|sleep}\n' "$0" >&2
    exit 2
    ;;
esac
