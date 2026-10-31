#!/bin/bash

# PostgreSQL Backup Script for n8n Docker Setup
# This script creates automated backups of the PostgreSQL database

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER_NAME="${CONTAINER_NAME:-n8n-docker-postgres-1}"
POSTGRES_DB="${POSTGRES_DB:-n8n}"
POSTGRES_USER="${POSTGRES_USER:-n8n}"
MAX_BACKUPS="${MAX_BACKUPS:-7}"

# Log file configuration
LOG_FILE="$BACKUP_DIR/backup-postgres_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages (both to console and log file)
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/n8n_backup_$(date +%Y%m%d_%H%M%S).sql"

log_message "Starting PostgreSQL backup at $(date)"
log_message "Backup file: $BACKUP_FILE"

# Create database dump
if docker exec "$CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$BACKUP_FILE"; then
    log_message "✅ Backup completed successfully"

    # Compress the backup
    gzip "$BACKUP_FILE"
    log_message "✅ Backup compressed: ${BACKUP_FILE}.gz"

    # Clean up old backups (keep only MAX_BACKUPS)
    if [ "$MAX_BACKUPS" -gt 0 ]; then
        find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -type f | sort -r | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
        log_message "🧹 Cleaned up old backups (keeping $MAX_BACKUPS most recent)"
    fi

    # Log backup info
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    log_message "📊 Backup size: $BACKUP_SIZE"
    log_message "✅ PostgreSQL backup completed at $(date)"

else
    log_message "❌ Backup failed at $(date)"
    exit 1
fi
