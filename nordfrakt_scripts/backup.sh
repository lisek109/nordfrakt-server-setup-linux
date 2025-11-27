#!/bin/bash
# backup.sh
# Tar og synkroniserer sikkerhetskopi av Nordfrakt-data til backup-server

SOURCE_DIR="/srv/nordfrakt"
BACKUP_SERVER="server-backup"
BACKUP_BASE="/srv/backup"
DATE=$(date +%F)   # YYYY-MM-DD

echo "Starter sikkerhetskopi $DATE..."

# Opprett lokal arkiv med tar (valgfritt hvis du vil ha komprimert kopi)
ARCHIVE="/tmp/nordfrakt_backup_$DATE.tar.gz"
sudo tar -czf "$ARCHIVE" -C "$SOURCE_DIR" .

# Overfør til backup-server med rsync
sudo rsync -az "$ARCHIVE" "$BACKUP_SERVER:$BACKUP_BASE/"

# Rotasjon: behold kun 7 daglige kopier
ssh "$BACKUP_SERVER" "ls -1t $BACKUP_BASE/nordfrakt_backup_*.tar.gz | tail -n +8 | xargs -r rm --"

echo "Backup fullført: $ARCHIVE sendt til $BACKUP_SERVER:$BACKUP_BASE"
