# Gumroad product listing

## Title
backup-kit — Automated, verified backups for self-hosters

## Tagline
Backups that prove themselves. restic/borg + restore verification + alerting.

## Price
19€ (one-time, lifetime updates)

## Description (paste into Gumroad)

Most backup scripts back up and pray. backup-kit proves your backups work.

Every run:
1. Backs up with restic or borg (your choice)
2. Applies retention (daily/weekly/monthly)
3. Restores the latest snapshot to a temp dir
4. Compares SHA-256 checksums of a sampled file set
5. Runs `restic check --read-data` integrity scan
6. Alerts you via webhook and/or email if anything fails

**What you get**
- `backup.sh` — the main runner
- `verify-restore.sh` — standalone verification
- `alert.sh` — webhook + email
- `install.sh` — systemd timer (daily 02:30) + cron fallback
- Config template + docs

**Requirements**
- Linux (Debian/Ubuntu/Fedora/Arch)
- restic >= 0.16 or borgbackup >= 1.2
- bash, curl, flock, sha256sum, shuf

**License:** MIT — use freely, modify, resell derivatives.

**Refund:** 30 days, no questions.

## Cover image suggestion
Dark terminal screenshot showing "Verification PASSED" + green checkmark. 1280x720.

## Tags
backup, restic, borg, self-hosting, homelab, linux, automation, devops
