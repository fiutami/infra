#!/bin/bash
# =============================================================================
# FIUTAMI - Sync Production Database to Staging
# =============================================================================
# Questo script sincronizza il database di produzione su staging.
# ATTENZIONE: Sovrascrive completamente il database di staging!
#
# Usage: ./sync-prod-to-stage.sh [--dry-run]
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROD_SERVER="49.12.85.92"
STAGE_SERVER="91.99.229.111"
PROD_SSH_KEY="~/.ssh/id_hetzner"
STAGE_SSH_KEY="~/.ssh/id_stage_new"
PROD_DB_CONTAINER="fiutami-db-prod"
STAGE_DB_CONTAINER="fiutami-db-stage"
DB_NAME="fiutami_prod"
STAGE_DB_NAME="fiutami_stage"
BACKUP_DIR="/var/opt/mssql/backup"
LOCAL_TEMP="/tmp/fiutami-sync"
BACKUP_FILE="fiutami_sync_$(date +%Y%m%d_%H%M%S).bak"

# Parse arguments
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "${YELLOW}[DRY-RUN MODE] No changes will be made${NC}"
fi

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check SSH keys exist
check_ssh_keys() {
    log_info "Checking SSH keys..."

    if [ ! -f "$(eval echo $PROD_SSH_KEY)" ]; then
        log_error "Production SSH key not found: $PROD_SSH_KEY"
        exit 1
    fi

    if [ ! -f "$(eval echo $STAGE_SSH_KEY)" ]; then
        log_error "Staging SSH key not found: $STAGE_SSH_KEY"
        exit 1
    fi

    log_success "SSH keys found"
}

# Create local temp directory
setup_temp() {
    log_info "Setting up temp directory..."
    mkdir -p "$LOCAL_TEMP"
    log_success "Temp directory ready: $LOCAL_TEMP"
}

# Step 1: Create backup on production
create_prod_backup() {
    log_info "Creating backup on production server..."

    if [ "$DRY_RUN" == true ]; then
        log_warning "[DRY-RUN] Would create backup: $BACKUP_FILE"
        return
    fi

    ssh -i $(eval echo $PROD_SSH_KEY) root@$PROD_SERVER << EOF
        source /opt/fra/fiutami/.env

        # Ensure backup directory exists
        docker exec $PROD_DB_CONTAINER mkdir -p $BACKUP_DIR

        # Create backup
        docker exec $PROD_DB_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "\$DB_PASSWORD" -C \
            -Q "BACKUP DATABASE [$DB_NAME] TO DISK='$BACKUP_DIR/$BACKUP_FILE' WITH FORMAT, COMPRESSION"

        # Verify backup exists
        docker exec $PROD_DB_CONTAINER ls -la $BACKUP_DIR/$BACKUP_FILE
EOF

    log_success "Backup created: $BACKUP_FILE"
}

# Step 2: Copy backup from production to local
copy_backup_to_local() {
    log_info "Copying backup from production to local..."

    if [ "$DRY_RUN" == true ]; then
        log_warning "[DRY-RUN] Would copy backup to local"
        return
    fi

    # First copy from container to host
    ssh -i $(eval echo $PROD_SSH_KEY) root@$PROD_SERVER \
        "docker cp $PROD_DB_CONTAINER:$BACKUP_DIR/$BACKUP_FILE /tmp/$BACKUP_FILE"

    # Then copy from host to local
    scp -i $(eval echo $PROD_SSH_KEY) root@$PROD_SERVER:/tmp/$BACKUP_FILE "$LOCAL_TEMP/$BACKUP_FILE"

    # Cleanup on production
    ssh -i $(eval echo $PROD_SSH_KEY) root@$PROD_SERVER \
        "rm -f /tmp/$BACKUP_FILE && docker exec $PROD_DB_CONTAINER rm -f $BACKUP_DIR/$BACKUP_FILE"

    log_success "Backup copied to local: $LOCAL_TEMP/$BACKUP_FILE"
}

# Step 3: Copy backup from local to staging
copy_backup_to_stage() {
    log_info "Copying backup from local to staging..."

    if [ "$DRY_RUN" == true ]; then
        log_warning "[DRY-RUN] Would copy backup to staging"
        return
    fi

    # Copy to staging host
    scp -i $(eval echo $STAGE_SSH_KEY) "$LOCAL_TEMP/$BACKUP_FILE" root@$STAGE_SERVER:/tmp/$BACKUP_FILE

    # Copy to container
    ssh -i $(eval echo $STAGE_SSH_KEY) root@$STAGE_SERVER << EOF
        docker exec $STAGE_DB_CONTAINER mkdir -p $BACKUP_DIR
        docker cp /tmp/$BACKUP_FILE $STAGE_DB_CONTAINER:$BACKUP_DIR/$BACKUP_FILE
        rm -f /tmp/$BACKUP_FILE
EOF

    log_success "Backup copied to staging"
}

# Step 4: Restore backup on staging
restore_on_stage() {
    log_info "Restoring backup on staging server..."
    log_warning "This will OVERWRITE the staging database!"

    if [ "$DRY_RUN" == true ]; then
        log_warning "[DRY-RUN] Would restore backup to staging DB"
        return
    fi

    ssh -i $(eval echo $STAGE_SSH_KEY) root@$STAGE_SERVER << EOF
        source /opt/fiutami/.env

        # Kill existing connections
        docker exec $STAGE_DB_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "\$DB_PASSWORD" -C \
            -Q "ALTER DATABASE [$STAGE_DB_NAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE" 2>/dev/null || true

        # Get logical file names from backup
        echo "Getting logical file names from backup..."
        docker exec $STAGE_DB_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "\$DB_PASSWORD" -C \
            -Q "RESTORE FILELISTONLY FROM DISK='$BACKUP_DIR/$BACKUP_FILE'" | head -5

        # Restore with MOVE to stage paths (logical names are FIUTAMI and FIUTAMI_log)
        docker exec $STAGE_DB_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "\$DB_PASSWORD" -C \
            -Q "RESTORE DATABASE [$STAGE_DB_NAME] FROM DISK='$BACKUP_DIR/$BACKUP_FILE'
                WITH REPLACE,
                MOVE 'FIUTAMI' TO '/var/opt/mssql/data/${STAGE_DB_NAME}.mdf',
                MOVE 'FIUTAMI_log' TO '/var/opt/mssql/data/${STAGE_DB_NAME}_log.ldf'"

        # Set back to multi-user
        docker exec $STAGE_DB_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "\$DB_PASSWORD" -C \
            -Q "ALTER DATABASE [$STAGE_DB_NAME] SET MULTI_USER"

        # Cleanup backup file
        docker exec $STAGE_DB_CONTAINER rm -f $BACKUP_DIR/$BACKUP_FILE
EOF

    log_success "Database restored on staging"
}

# Step 5: Verify sync
verify_sync() {
    log_info "Verifying sync..."

    if [ "$DRY_RUN" == true ]; then
        log_warning "[DRY-RUN] Would verify sync"
        return
    fi

    # Count tables on staging
    STAGE_TABLES=$(ssh -i $(eval echo $STAGE_SSH_KEY) root@$STAGE_SERVER << 'EOF'
        source /opt/fiutami/.env
        docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_stage \
            -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -h -1
EOF
)

    log_success "Staging database has $STAGE_TABLES tables"

    # Verify POI count
    POI_COUNT=$(ssh -i $(eval echo $STAGE_SSH_KEY) root@$STAGE_SERVER << 'EOF'
        source /opt/fiutami/.env
        docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_stage \
            -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM POI_Points" -h -1 2>/dev/null || echo "0"
EOF
)

    log_success "POI count on staging: $POI_COUNT"
}

# Cleanup local temp
cleanup() {
    log_info "Cleaning up..."
    rm -rf "$LOCAL_TEMP"
    log_success "Cleanup complete"
}

# Main execution
main() {
    echo ""
    echo "======================================================"
    echo "  FIUTAMI - Sync Production → Staging"
    echo "======================================================"
    echo ""

    check_ssh_keys
    setup_temp

    echo ""
    log_warning "This will COMPLETELY OVERWRITE the staging database!"
    log_warning "Production data will be copied to staging."
    echo ""

    if [ "$DRY_RUN" == false ]; then
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log_error "Aborted by user"
            exit 1
        fi
    fi

    echo ""
    log_info "Starting sync process..."
    echo ""

    create_prod_backup
    copy_backup_to_local
    copy_backup_to_stage
    restore_on_stage
    verify_sync
    cleanup

    echo ""
    echo "======================================================"
    log_success "Sync completed successfully!"
    echo "======================================================"
    echo ""
    echo "Staging database is now a copy of production."
    echo "Test at: https://stage.fiutami.pet"
    echo ""
}

# Run main
main
