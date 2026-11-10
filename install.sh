#!/usr/bin/env bash
# backup-kit installer
set -euo pipefail

PREFIX="${PREFIX:-/opt/backup-kit}"
CONFIG_DIR="/etc/backup-kit"
BIN_DIR="/usr/local/bin"

echo "Installing backup-kit to $PREFIX ..."

install -d "$PREFIX/scripts" "$CONFIG_DIR" /var/log/backup-kit /var/lib/backup-kit
install -m 0755 scripts/*.sh "$PREFIX/scripts/"
install -m 0644 config/config.example.yaml "$CONFIG_DIR/config.example.yaml"

# symlinks
ln -sf "$PREFIX/scripts/backup.sh" "$BIN_DIR/backup-kit"
ln -sf "$PREFIX/scripts/verify-restore.sh" "$BIN_DIR/backup-kit-verify"

if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
  cp "$CONFIG_DIR/config.example.yaml" "$CONFIG_DIR/config.yaml"
  echo "Created $CONFIG_DIR/config.yaml — EDIT IT before running."
fi

# systemd unit
cat > /etc/systemd/system/backup-kit.service <<'EOF'
[Unit]
Description=backup-kit automated backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment=BACKUP_KIT_CONFIG=/etc/backup-kit/config.yaml
ExecStart=/usr/local/bin/backup-kit
User=root
EOF

cat > /etc/systemd/system/backup-kit.timer <<'EOF'
[Unit]
Description=Run backup-kit daily

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=300

[Unit]
Description=backup-kit daily timer

[Install]
WantedBy=timers.target
EOF

echo "Installed. Enable with: systemctl enable --now backup-kit.timer"
echo "Edit config: $CONFIG_DIR/config.yaml"
