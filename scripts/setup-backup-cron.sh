#!/bin/bash

# Setup automated PostgreSQL backups via cron
# This script configures cron jobs for regular database backups

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-postgres.sh"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Log file configuration
LOG_FILE="$BACKUP_DIR/setup-backup-cron_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages (both to console and log file)
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

log_message "Setting up automated PostgreSQL backups..."

# Create crontab entry for daily backups at 2 AM
CRON_JOB="0 2 * * * cd $(dirname "$SCRIPT_DIR") && $BACKUP_SCRIPT >> /var/log/n8n-backup.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
    log_message "⚠️  Backup cron job already exists"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_message "✅ Added daily backup cron job (runs at 2 AM)"
fi

# Create log directory
sudo mkdir -p /var/log
sudo touch /var/log/n8n-backup.log
sudo chmod 644 /var/log/n8n-backup.log

log_message "📋 Cron job added:"
log_message "   Daily backups at 2:00 AM"
log_message "   Logs: /var/log/n8n-backup.log"
log_message ""
log_message "To view current cron jobs: crontab -l"
log_message "To remove backup cron job: crontab -e (and delete the backup line)"
log_message ""
log_message "✅ Automated backup setup completed!"
