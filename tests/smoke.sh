#!/usr/bin/env bash
# Smoke test: runs backup + verify against a temp repo
set -euo pipefail
export PATH="/home/hermes/.local/bin:$PATH"
TMP=$(mktemp -d)
mkdir -p "$TMP/src/sub"
echo hi > "$TMP/src/a.txt"
echo nested > "$TMP/src/sub/b.txt"
printf 'secret123\n' > "$TMP/pass"
cat > "$TMP/config.yaml" <<EOF
backend: restic
repository: $TMP/repo
password_file: $TMP/pass
source_paths: $TMP/src
verify_restore: true
retention_keep_daily: 7
retention_keep_weekly: 4
retention_keep_monthly: 6
EOF
export BACKUP_KIT_CONFIG="$TMP/config.yaml"
export BACKUP_KIT_LOG_DIR="$TMP/logs"
export BACKUP_KIT_STATE_DIR="$TMP/state"
mkdir -p "$BACKUP_KIT_LOG_DIR" "$BACKUP_KIT_STATE_DIR"
restic -r "$TMP/repo" init --password-file "$TMP/pass" >/dev/null
bash /home/hermes/backup-kit/scripts/backup.sh >/tmp/smoke.log 2>&1
echo "backup exit: $?"
grep -q "Verification PASSED" /tmp/smoke.log && echo "SMOKE OK" || { echo "SMOKE FAIL"; cat /tmp/smoke.log; exit 1; }
rm -rf "$TMP"
