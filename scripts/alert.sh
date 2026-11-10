#!/usr/bin/env bash
# backup-kit: alerting helper
# Usage: alert.sh <event> <message> [level]
set -euo pipefail

CONFIG_FILE="${BACKUP_KIT_CONFIG:-/etc/backup-kit/config.yaml}"
cfg() {
  local key="$1" def="${2:-}"
  local val
  val=$(grep -E "^[[:space:]]*${key}:" "$CONFIG_FILE" 2>/dev/null | head -n1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')
  [[ -z "$val" ]] && echo "$def" || echo "$val"
}

EVENT="${1:-unknown}"
MESSAGE="${2:-no message}"
LEVEL="${3:-error}"

WEBHOOK="$(cfg alert_webhook '')"
EMAIL="$(cfg alert_email '')"
HOSTNAME="$(hostname)"

payload="{\"event\":\"$EVENT\",\"level\":\"$LEVEL\",\"host\":\"$HOSTNAME\",\"message\":\"$MESSAGE\",\"ts\":\"$(date -Iseconds)\"}"

if [[ -n "$WEBHOOK" ]]; then
  if command -v curl >/dev/null 2>&1; then
    curl -sS -X POST -H 'Content-Type: application/json' -d "$payload" "$WEBHOOK" >/dev/null 2>&1 || true
  fi
fi

if [[ -n "$EMAIL" ]]; then
  if command -v mail >/dev/null 2>&1; then
    printf 'Subject: [backup-kit] %s on %s\n\n%s\n' "$EVENT" "$HOSTNAME" "$MESSAGE" | mail -s "[backup-kit] $EVENT" "$EMAIL" 2>/dev/null || true
  elif command -v sendmail >/dev/null 2>&1; then
    printf 'To: %s\nSubject: [backup-kit] %s on %s\n\n%s\n' "$EMAIL" "$EVENT" "$HOSTNAME" "$MESSAGE" | sendmail "$EMAIL" 2>/dev/null || true
  fi
fi

# always log to syslog if available
if command -v logger >/dev/null 2>&1; then
  logger -t backup-kit "[$LEVEL] $EVENT: $MESSAGE" 2>/dev/null || true
fi

exit 0
