# FAQ

**Q: restic or borg?**
A: Either. Set `backend:` in config.

**Q: Cloud storage?**
A: restic supports S3, B2, Azure, GCS, rclone. borg supports ssh. Set `repository:` accordingly.

**Q: Raspberry Pi?**
A: Yes, any Linux with restic/borg.

**Q: How often does it run?**
A: Daily 02:30 via systemd timer. Edit the timer or use cron.

**Q: What if restore verification fails?**
A: Alert is sent (webhook/email) and exit code is non-zero. The backup itself already succeeded; only verification failed.

**Q: Can I exclude paths?**
A: Yes, via excludes_file (restic --exclude-file / borg --exclude-from).

**Q: License?**
A: MIT. Use, modify, resell freely.
