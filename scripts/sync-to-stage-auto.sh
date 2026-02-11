#!/bin/bash
# =============================================================================
# FIUTAMI - Auto Sync Production to Staging
# Runs every 15 minutes via cron on production server
# Deploy to: /opt/fra/fiutami/scripts/sync-to-stage.sh
# =============================================================================

LOG_FILE="/var/log/fiutami-sync.log"
LOCK_FILE="/tmp/fiutami-sync.lock"
STAGE_SERVER="91.99.229.111"
STAGE_SSH_KEY="/root/.ssh/id_stage"
BACKUP_FILE="fiutami_sync.bak"

# Prevent concurrent runs (with stale lock detection)
if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
    if [ "$LOCK_AGE" -gt 600 ]; then
        rm -f "$LOCK_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Sync already running, skipping" >> "$LOG_FILE"
        exit 0
    fi
fi
trap "rm -f $LOCK_FILE" EXIT
touch "$LOCK_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "=== Starting sync ==="

# Load env
source /opt/fra/fiutami/.env

# Create backup
log "Creating backup..."
BACKUP_OUTPUT=$(docker exec fiutami-db-prod /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C \
    -Q "BACKUP DATABASE [fiutami_prod] TO DISK='/var/opt/mssql/data/$BACKUP_FILE' WITH FORMAT, INIT" 2>&1)

if [ $? -ne 0 ]; then
    log "ERROR: Backup failed - $BACKUP_OUTPUT"
    exit 1
fi
log "Backup created OK"

# Copy to host
docker cp fiutami-db-prod:/var/opt/mssql/data/$BACKUP_FILE /tmp/$BACKUP_FILE
docker exec fiutami-db-prod rm -f /var/opt/mssql/data/$BACKUP_FILE
BACKUP_SIZE=$(ls -lh /tmp/$BACKUP_FILE 2>/dev/null | awk '{print $5}')
log "Backup copied to host, size: $BACKUP_SIZE"

# Copy to staging server
scp -i "$STAGE_SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=30 \
    "/tmp/$BACKUP_FILE" "root@${STAGE_SERVER}:/tmp/${BACKUP_FILE}" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    log "ERROR: SCP to staging failed"
    rm -f /tmp/$BACKUP_FILE
    exit 1
fi
log "Backup copied to staging server"

# Restore on staging via SSH
log "Starting restore on staging..."

ssh -i "$STAGE_SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=30 "root@${STAGE_SERVER}" bash << 'ENDSSH'
source /opt/fiutami/.env
BACKUP_FILE="fiutami_sync.bak"

# Copy backup into container
docker cp /tmp/$BACKUP_FILE fiutami-db-stage:/var/opt/mssql/data/$BACKUP_FILE
rm -f /tmp/$BACKUP_FILE

# Fix permissions - run as root user inside container
docker exec -u root fiutami-db-stage chown mssql:root /var/opt/mssql/data/$BACKUP_FILE

# Set single user mode to kill connections
docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C \
    -Q "IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'fiutami_stage') ALTER DATABASE [fiutami_stage] SET SINGLE_USER WITH ROLLBACK IMMEDIATE" 2>/dev/null || true

# Restore database (logical names are FIUTAMI and FIUTAMI_log)
docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C \
    -Q "RESTORE DATABASE [fiutami_stage] FROM DISK='/var/opt/mssql/data/$BACKUP_FILE' WITH REPLACE, MOVE 'FIUTAMI' TO '/var/opt/mssql/data/fiutami_stage.mdf', MOVE 'FIUTAMI_log' TO '/var/opt/mssql/data/fiutami_stage_log.ldf'"

RESTORE_RESULT=$?

# Set multi user mode
docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C \
    -Q "ALTER DATABASE [fiutami_stage] SET MULTI_USER" 2>/dev/null || true

# Cleanup backup file
docker exec fiutami-db-stage rm -f /var/opt/mssql/data/$BACKUP_FILE

# Verify - count POIs
POI_COUNT=$(docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_stage \
    -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM POI_Points" -h -1 2>/dev/null | tr -d ' ')

echo "POI_COUNT=$POI_COUNT"
exit $RESTORE_RESULT
ENDSSH

REMOTE_RESULT=$?
if [ $REMOTE_RESULT -ne 0 ]; then
    log "ERROR: Restore on staging failed with code $REMOTE_RESULT"
else
    log "Restore completed successfully"
fi

# Cleanup local
rm -f /tmp/$BACKUP_FILE

log "=== Sync finished ==="

# Keep only last 200 lines of log
tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

exit $REMOTE_RESULT
