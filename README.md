# backup-kit

**Automated, verified backups for self-hosters.** restic or borg under the hood, with restore verification and alerting built in.

> Sell price target: ~19€ on Gumroad. One-time purchase, lifetime updates.

## Why

Most backup scripts back up and pray. backup-kit **proves** your backups work: every run restores the latest snapshot to a temp dir and compares checksums, then alerts you if anything is off.

## Features

- restic or borg backend (your choice)
- Retention policies (daily/weekly/monthly)
- Restore verification with sampled SHA-256 checksum comparison
- `restic check --read-data` integrity scan
- Alerting via webhook (Slack/Discord/ntfy) and/or email
- systemd timer (daily 02:30) + cron fallback
- Lock file prevents overlapping runs
- Configurable excludes

## Quick start

```bash
git clone https://github.com/yourname/backup-kit
cd backup-kit
sudo ./install.sh
sudo nano /etc/backup-kit/config.yaml
sudo systemctl enable --now backup-kit.timer
sudo backup-kit            # manual run
```

## Requirements

- Linux (Debian/Ubuntu/Fedora/Arch)
- restic >= 0.16 or borgbackup >= 1.2
- bash, curl, flock, sha256sum, shuf

## Configuration

See `config/config.example.yaml`.

## Restore verification

`verify-restore.sh` restores the latest snapshot into `/var/lib/backup-kit/verify-*`, samples up to 50 files, compares SHA-256 to source, and runs `restic check --read-data-subset=5%`. Fails (and alerts) on any mismatch.

## Alerting

Webhook receives JSON: `{"event","level","host","message","ts"}`. Email via `mail`/`sendmail`.

## License

MIT. Use freely, sell freely.

---
Built by Dina & Hermes.
