#!/bin/bash

# Redis Backup Script for n8n Docker Setup
# This script creates automated backups of Redis data

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER_NAME="${CONTAINER_NAME:-n8n-docker-redis-1}"
MAX_BACKUPS="${MAX_BACKUPS:-7}"

# Log file configuration
LOG_FILE="$BACKUP_DIR/backup-redis_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages (both to console and log file)
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/redis_backup_$(date +%Y%m%d_%H%M%S).rdb"

log_message "Starting Redis backup at $(date)"
log_message "Backup file: $BACKUP_FILE"

# Trigger Redis to save current state
log_message "💾 Triggering Redis BGSAVE..."
if docker exec "$CONTAINER_NAME" redis-cli BGSAVE; then
    log_message "✅ Redis BGSAVE triggered successfully"
else
    log_message "❌ Failed to trigger Redis BGSAVE"
    exit 1
fi

# Wait for background save to complete
log_message "⏳ Waiting for background save to complete..."
START_TIME=$(date)
INITIAL_LASTSAVE=$(docker exec "$CONTAINER_NAME" redis-cli LASTSAVE)
while true; do
    sleep 2
    CURRENT_LASTSAVE=$(docker exec "$CONTAINER_NAME" redis-cli LASTSAVE)
    if [ "$CURRENT_LASTSAVE" != "$INITIAL_LASTSAVE" ]; then
        log_message "✅ Background save completed"
        break
    fi
    # Add timeout to prevent infinite waiting (max 60 seconds)
    ELAPSED=$(($(date +%s) - $(date -d "$START_TIME" +%s 2>/dev/null || echo 0)))
    if [ $ELAPSED -gt 60 ]; then
        log_message "⚠️  Timeout waiting for BGSAVE, proceeding anyway"
        break
    fi
done

# Copy the RDB file from container
if docker cp "$CONTAINER_NAME:/data/dump.rdb" "$BACKUP_FILE"; then
    log_message "✅ Redis data backed up successfully"

    # Compress the backup
    gzip "$BACKUP_FILE"
    log_message "✅ Backup compressed: ${BACKUP_FILE}.gz"

    # Also backup AOF file if it exists
    AOF_BACKUP="${BACKUP_FILE%.rdb}.aof"
    if docker exec "$CONTAINER_NAME" test -f /data/appendonly.aof; then
        if docker cp "$CONTAINER_NAME:/data/appendonly.aof" "$AOF_BACKUP"; then
            gzip "$AOF_BACKUP"
            log_message "✅ AOF file backed up: ${AOF_BACKUP}.gz"
        else
            log_message "⚠️  Could not backup AOF file (may not exist)"
        fi
    else
        log_message "ℹ️  No AOF file found (normal if AOF is disabled)"
    fi

    # Clean up old backups (keep only MAX_BACKUPS)
    if [ "$MAX_BACKUPS" -gt 0 ]; then
        find "$BACKUP_DIR" -name "redis_backup_*.rdb.gz" -type f | sort -r | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
        find "$BACKUP_DIR" -name "redis_backup_*.aof.gz" -type f | sort -r | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
        log_message "🧹 Cleaned up old backups (keeping $MAX_BACKUPS most recent)"
    fi

    # Log backup info
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    log_message "📊 Backup size: $BACKUP_SIZE"
    log_message "✅ Redis backup completed at $(date)"

else
    log_message "❌ Redis backup failed at $(date)"
    exit 1
fi
