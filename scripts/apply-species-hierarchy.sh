#!/bin/bash
# =============================================================================
# FIUTAMI - Apply Species Hierarchy Migration
#
# Applies AddSpeciesHierarchy + SeedExpandedSpecies to target database.
# Idempotent: safe to run multiple times.
#
# Usage:
#   ./apply-species-hierarchy.sh prod     # Apply to production
#   ./apply-species-hierarchy.sh stage    # Apply to staging
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="$SCRIPT_DIR/apply-species-hierarchy.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "ERROR: SQL file not found: $SQL_FILE"
    exit 1
fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Usage: $0 <prod|stage>"
    exit 1
fi

case "$TARGET" in
    prod)
        SERVER="49.12.85.92"
        SSH_KEY="$HOME/.ssh/id_hetzner"
        CONTAINER="fiutami-db-prod"
        DATABASE="fiutami_prod"
        ENV_FILE="/opt/fra/fiutami/.env"
        ;;
    stage)
        SERVER="91.99.229.111"
        SSH_KEY="$HOME/.ssh/id_stage_new"
        CONTAINER="fiutami-db-stage"
        DATABASE="fiutami_stage"
        ENV_FILE="/opt/fiutami/.env"
        ;;
    *)
        echo "ERROR: Unknown target '$TARGET'. Use 'prod' or 'stage'."
        exit 1
        ;;
esac

echo "=== Applying Species Hierarchy to $TARGET ==="
echo "  Server:    $SERVER"
echo "  Container: $CONTAINER"
echo "  Database:  $DATABASE"
echo ""

# Copy SQL file to server
echo "Copying SQL to server..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SQL_FILE" "root@${SERVER}:/tmp/apply-species-hierarchy.sql"

# Copy into container and execute
echo "Executing on $TARGET..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "root@${SERVER}" bash << ENDSSH
source $ENV_FILE
docker cp /tmp/apply-species-hierarchy.sql $CONTAINER:/tmp/apply-species-hierarchy.sql
docker exec $CONTAINER /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "\$DB_PASSWORD" -C -d $DATABASE \
    -i /tmp/apply-species-hierarchy.sql
docker exec $CONTAINER rm -f /tmp/apply-species-hierarchy.sql
rm -f /tmp/apply-species-hierarchy.sql
ENDSSH

echo ""
echo "=== Done! ==="
