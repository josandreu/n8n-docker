#!/bin/bash

# Enhanced PostgreSQL initialization script with error handling and retry logic
set -euo pipefail

# Configuration variables
readonly MAX_RETRIES=5
readonly RETRY_DELAY=2
readonly LOG_PREFIX="[INIT-DATA]"

# Logging functions
log_info() {
    echo "${LOG_PREFIX} INFO: $*" >&2
}

log_error() {
    echo "${LOG_PREFIX} ERROR: $*" >&2
}

log_warn() {
    echo "${LOG_PREFIX} WARN: $*" >&2
}

# Function to check if PostgreSQL is ready
check_postgres_ready() {
    local attempt=1
    local max_attempts=30

    log_info "Checking if PostgreSQL is ready..."

    while [ $attempt -le $max_attempts ]; do
        if pg_isready -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            return 0
        fi

        log_info "PostgreSQL not ready yet (attempt $attempt/$max_attempts), waiting..."
        sleep 2
        ((attempt++))
    done

    log_error "PostgreSQL failed to become ready after $max_attempts attempts"
    return 1
}

# Function to execute SQL with retry logic
execute_sql_with_retry() {
    local sql="$1"
    local description="$2"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "Executing $description (attempt $attempt/$MAX_RETRIES)"

        if psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "$sql" >/dev/null 2>&1; then
            log_info "$description completed successfully"
            return 0
        else
            local exit_code=$?
            log_warn "$description failed on attempt $attempt (exit code: $exit_code)"

            if [ $attempt -eq $MAX_RETRIES ]; then
                log_error "$description failed after $MAX_RETRIES attempts"
                return $exit_code
            fi

            log_info "Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
            ((attempt++))
        fi
    done
}

# Function to check if user already exists
user_exists() {
    local username="$1"
    local query="SELECT 1 FROM pg_roles WHERE rolname='$username';"

    if psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -t -c "$query" 2>/dev/null | grep -q 1; then
        return 0
    else
        return 1
    fi
}

# Function to validate environment variables
validate_environment() {
    local missing_vars=()

    # Check required PostgreSQL variables
    if [ -z "${POSTGRES_USER:-}" ]; then
        missing_vars+=("POSTGRES_USER")
    fi

    if [ -z "${POSTGRES_DB:-}" ]; then
        missing_vars+=("POSTGRES_DB")
    fi

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi

    # Check if non-root user variables are provided
    if [ -z "${POSTGRES_NON_ROOT_USER:-}" ] || [ -z "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
        log_warn "POSTGRES_NON_ROOT_USER or POSTGRES_NON_ROOT_PASSWORD not provided"
        return 1
    fi

    return 0
}

# Main execution function
main() {
    log_info "Starting PostgreSQL initialization script"

    # Validate environment variables
    if ! validate_environment; then
        log_info "Skipping non-root user creation due to missing environment variables"
        return 0
    fi

    log_info "Environment validation passed"
    log_info "Target database: $POSTGRES_DB"
    log_info "Non-root user: $POSTGRES_NON_ROOT_USER"

    # Wait for PostgreSQL to be ready
    if ! check_postgres_ready; then
        log_error "PostgreSQL readiness check failed"
        exit 1
    fi

    # Check if user already exists
    if user_exists "$POSTGRES_NON_ROOT_USER"; then
        log_info "User '$POSTGRES_NON_ROOT_USER' already exists, skipping creation"
        return 0
    fi

    # Create user with retry logic
    local create_user_sql="CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';"
    if ! execute_sql_with_retry "$create_user_sql" "user creation"; then
        log_error "Failed to create user '$POSTGRES_NON_ROOT_USER'"
        exit 1
    fi

    # Grant database privileges with retry logic
    local grant_db_sql="GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};"
    if ! execute_sql_with_retry "$grant_db_sql" "database privileges grant"; then
        log_error "Failed to grant database privileges to '$POSTGRES_NON_ROOT_USER'"
        exit 1
    fi

    # Grant schema privileges with retry logic
    local grant_schema_sql="GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};"
    if ! execute_sql_with_retry "$grant_schema_sql" "schema privileges grant"; then
        log_error "Failed to grant schema privileges to '$POSTGRES_NON_ROOT_USER'"
        exit 1
    fi

    # Verify user permissions
    log_info "Verifying user permissions..."
    local verify_sql="SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname='${POSTGRES_NON_ROOT_USER}';"
    if psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "$verify_sql"; then
        log_info "User verification completed successfully"
    else
        log_warn "User verification failed, but user creation appeared successful"
    fi

    log_info "PostgreSQL initialization completed successfully"
}

# Error trap handler
error_handler() {
    local exit_code=$?
    log_error "Script failed with exit code $exit_code at line $1"
    exit $exit_code
}

# Set up error handling
trap 'error_handler $LINENO' ERR

# Execute main function
main "$@"
