#!/bin/bash
# =============================================================================
# FIUTAMI - Disable Destructive Prod→Stage Sync Cron
#
# Disables the */15 cron job that does RESTORE DATABASE (destroys staging schema).
# Replaces it with a reminder to use import-prod-data.sh (non-destructive MERGE).
#
# Run from: local machine (connects to prod server via SSH)
# =============================================================================

set -euo pipefail

PROD_SERVER="49.12.85.92"
SSH_KEY="$HOME/.ssh/id_hetzner"

echo "=== Disabling destructive sync cron on production ==="
echo ""

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "root@${PROD_SERVER}" bash << 'ENDSSH'

# Show current crontab
echo "Current crontab:"
crontab -l 2>/dev/null || echo "(empty)"
echo ""

# Backup current crontab
crontab -l > /tmp/crontab-backup-$(date +%Y%m%d).txt 2>/dev/null || true

# Comment out the sync line (if it exists)
if crontab -l 2>/dev/null | grep -q "sync-to-stage"; then
    crontab -l | sed 's|^\(.*/sync-to-stage.*\)|# DISABLED $(date +%Y-%m-%d) - use import-prod-data.sh instead\n# \1|' | crontab -
    echo "Destructive sync cron DISABLED."
else
    echo "No sync cron found (already disabled or never set)."
fi

echo ""
echo "Updated crontab:"
crontab -l 2>/dev/null || echo "(empty)"

echo ""
echo "To sync data manually (non-destructive), run:"
echo "  /opt/fra/fiutami/scripts/import-prod-data.sh"
echo "  /opt/fra/fiutami/scripts/import-prod-data.sh --dry-run  # preview only"

ENDSSH

echo ""
echo "=== Done ==="
