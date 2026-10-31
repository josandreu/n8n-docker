#!/bin/bash

# Master Backup Script for n8n Docker Setup
# This script runs both PostgreSQL and Redis backups

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Log file configuration
LOG_FILE="$BACKUP_DIR/backup-all_$(date +%Y%m%d_%H%M%S).log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages (both to console and log file)
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

log_message "🚀 Starting comprehensive n8n backup at $(date)"
log_message "=============================================="

# Run PostgreSQL backup
log_message "📊 Running PostgreSQL backup..."
if "$SCRIPT_DIR/backup-postgres.sh"; then
    log_message "✅ PostgreSQL backup completed"
else
    log_message "❌ PostgreSQL backup failed"
    exit 1
fi

log_message ""

# Run Redis backup
log_message "🔧 Running Redis backup..."
if "$SCRIPT_DIR/backup-redis.sh"; then
    log_message "✅ Redis backup completed"
else
    log_message "❌ Redis backup failed"
    exit 1
fi

log_message ""
log_message "=============================================="
log_message "✅ All backups completed successfully at $(date)"
log_message "📁 Backups stored in:"
log_message "   - PostgreSQL: ./backups/ directory"
log_message "   - Redis: ./backups/ directory"
log_message ""
log_message "💡 To restore backups:"
log_message "   - PostgreSQL: ./scripts/restore-postgres.sh [backup_file]"
log_message "   - Redis: Restore RDB/AOF files manually to Redis data volume"
