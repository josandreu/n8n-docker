#!/bin/bash

# PostgreSQL Restore Script for n8n Docker Setup
# This script restores PostgreSQL database from backup files

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER_NAME="${CONTAINER_NAME:-n8n-docker-postgres-1}"
POSTGRES_DB="${POSTGRES_DB:-n8n}"
POSTGRES_USER="${POSTGRES_USER:-n8n}"

# Function to show usage
usage() {
    echo "Usage: $0 [backup_file]"
    echo ""
    echo "Restore PostgreSQL database from backup"
    echo ""
    echo "Arguments:"
    echo "  backup_file    Path to backup file (.sql or .sql.gz)"
    echo "                 If not specified, shows available backups"
    echo ""
    echo "Examples:"
    echo "  $0                                    # List available backups"
    echo "  $0 backups/n8n_backup_20250810_140000.sql.gz    # Restore specific backup"
    echo "  $0 latest                             # Restore latest backup"
}

# Function to list available backups
list_backups() {
    echo "📁 Available backups in $BACKUP_DIR:"
    echo ""
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR/*.sql.gz 2>/dev/null)" ]; then
        ls -lht "$BACKUP_DIR"/*.sql.gz | head -10
        echo ""
        echo "💡 Use 'latest' to restore the most recent backup"
    else
        echo "❌ No backups found in $BACKUP_DIR"
        echo "   Run backup-postgres.sh first to create backups"
    fi
}

# Function to restore backup
restore_backup() {
    local backup_file="$1"

    # Handle 'latest' keyword
    if [ "$backup_file" = "latest" ]; then
        backup_file=$(ls -t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            echo "❌ No backup files found"
            exit 1
        fi
        echo "📦 Using latest backup: $backup_file"
    fi

    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        exit 1
    fi

    echo "🔄 Starting database restore from: $backup_file"
    echo "⚠️  This will REPLACE all data in the database!"

    # Confirm restore action
    read -p "Continue with restore? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Restore cancelled"
        exit 0
    fi

    # Stop n8n containers to prevent data conflicts
    echo "🛑 Stopping n8n services..."
    docker-compose stop n8n n8n-worker 2>/dev/null || true

    # Restore database
    echo "📥 Restoring database..."
    if [[ "$backup_file" == *.gz ]]; then
        # Compressed backup
        if gunzip -c "$backup_file" | docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
            echo "✅ Database restored successfully from compressed backup"
        else
            echo "❌ Database restore failed"
            exit 1
        fi
    else
        # Uncompressed backup
        if docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$backup_file"; then
            echo "✅ Database restored successfully"
        else
            echo "❌ Database restore failed"
            exit 1
        fi
    fi

    # Restart n8n services
    echo "▶️  Starting n8n services..."
    docker-compose up -d n8n n8n-worker

    echo "✅ Restore completed successfully!"
    echo "🔗 n8n should be available at http://localhost:5678"
}

# Main script logic
if [ $# -eq 0 ]; then
    list_backups
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
else
    restore_backup "$1"
fi
