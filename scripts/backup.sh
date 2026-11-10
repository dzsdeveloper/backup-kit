#!/usr/bin/env bash
# backup-kit: automated, verified backups for self-hosters
# Copyright (c) 2026 Dina — licensed under MIT for personal/commercial use.
set -euo pipefail

# ---------- config ----------
CONFIG_FILE="${BACKUP_KIT_CONFIG:-/etc/backup-kit/config.yaml}"
LOG_DIR="${BACKUP_KIT_LOG_DIR:-/var/log/backup-kit}"
STATE_DIR="${BACKUP_KIT_STATE_DIR:-/var/lib/backup-kit}"
LOCK_FILE="${STATE_DIR}/backup.lock"

mkdir -p "$LOG_DIR" "$STATE_DIR"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${LOG_DIR}/backup.log"; }
err() { log "ERROR: $*"; }

# ---------- parse minimal yaml (key: value) ----------
cfg() {
  # cfg KEY [default]
  local key="$1" def="${2:-}"
  local val
  val=$(grep -E "^[[:space:]]*${key}:" "$CONFIG_FILE" 2>/dev/null | head -n1 | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')
  if [[ -z "$val" ]]; then echo "$def"; else echo "$val"; fi
}

# ---------- lock ----------
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  err "Another backup run is in progress. Exiting."
  exit 1
fi

# ---------- load config ----------
BACKEND="$(cfg backend restic)"          # restic | borg
REPO="$(cfg repository '')"
PASSWORD_FILE="$(cfg password_file '')"
SOURCE_PATHS="$(cfg source_paths '')"    # space-separated
RETENTION_KEEP_DAILY="$(cfg retention_keep_daily 7)"
RETENTION_KEEP_WEEKLY="$(cfg retention_keep_weekly 4)"
RETENTION_KEEP_MONTHLY="$(cfg retention_keep_monthly 6)"
VERIFY_RESTORE="$(cfg verify_restore true)"
ALERT_WEBHOOK="$(cfg alert_webhook '')"
ALERT_EMAIL="$(cfg alert_email '')"
EXCLUDES_FILE="$(cfg excludes_file '')"

if [[ -z "$REPO" ]]; then err "repository is required in config"; exit 2; fi
if [[ -z "$SOURCE_PATHS" ]]; then err "source_paths is required in config"; exit 2; fi

export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
export BORG_PASSPHRASE_FILE="$PASSWORD_FILE" 2>/dev/null || true

run_restic() {
  restic -r "$REPO" "$@"
}
run_borg() {
  borg "$@"
}

log "Starting backup (backend=$BACKEND)"

# ---------- backup ----------
START_TS=$(date +%s)
if [[ "$BACKEND" == "borg" ]]; then
  ARCHIVE_NAME="backup-$(date +%Y%m%d-%H%M%S)"
  borg create --stats --compression lz4 \
    ${EXCLUDES_FILE:+--exclude-from "$EXCLUDES_FILE"} \
    "$REPO::$ARCHIVE_NAME" $SOURCE_PATHS 2>&1 | tee -a "${LOG_DIR}/backup.log"
  borg prune -v "$REPO" \
    --keep-daily="$RETENTION_KEEP_DAILY" \
    --keep-weekly="$RETENTION_KEEP_WEEKLY" \
    --keep-monthly="$RETENTION_KEEP_MONTHLY" 2>&1 | tee -a "${LOG_DIR}/backup.log"
else
  restic -r "$REPO" backup $SOURCE_PATHS \
    ${EXCLUDES_FILE:+--exclude-file="$EXCLUDES_FILE"} \
    --tag "backup-kit" 2>&1 | tee -a "${LOG_DIR}/backup.log"
  restic -r "$REPO" forget \
    --keep-daily "$RETENTION_KEEP_DAILY" \
    --keep-weekly "$RETENTION_KEEP_WEEKLY" \
    --keep-monthly "$RETENTION_KEEP_MONTHLY" \
    --prune 2>&1 | tee -a "${LOG_DIR}/backup.log"
fi

BACKUP_RC=$?
END_TS=$(date +%s)
DURATION=$((END_TS - START_TS))

if [[ $BACKUP_RC -ne 0 ]]; then
  log "Backup FAILED (rc=$BACKUP_RC) after ${DURATION}s"
  bash "$(dirname "$0")/alert.sh" "backup_failed" "Backup failed (rc=$BACKUP_RC) after ${DURATION}s" || true
  exit $BACKUP_RC
fi

log "Backup OK in ${DURATION}s"

# ---------- verify restore ----------
if [[ "$VERIFY_RESTORE" == "true" ]]; then
  log "Running restore verification..."
  if ! bash "$(dirname "$0")/verify-restore.sh"; then
    log "Restore verification FAILED"
    bash "$(dirname "$0")/alert.sh" "restore_verify_failed" "Restore verification failed" || true
    exit 3
  fi
  log "Restore verification OK"
fi

log "All done."
bash "$(dirname "$0")/alert.sh" "backup_ok" "Backup + verify OK in ${DURATION}s" "info" || true
exit 0
