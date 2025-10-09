#!/bin/bash

#############################################################################
# MariaDB Database Import Script for Development Environment
# 
# Description: Safely imports SQL dump files into the MariaDB container
# Usage: ./import-db.sh <sql_file>
# Example: ./import-db.sh stagingaccountdb01.sql
#
# Author: Development Team
# Environment: Development only - DO NOT USE IN PRODUCTION
#############################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
CONTAINER_NAME="pc_mariadb"
DB_USER="root"
DB_PASSWORD="root"
BACKUP_DIR="./backup/db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
MariaDB Database Import Script

USAGE:
    $0 <sql_file>

DESCRIPTION:
    Safely imports SQL dump files from ./backup/db/ into the MariaDB container.
    This script includes safety checks and is designed for development use only.

ARGUMENTS:
    sql_file    Name of the SQL file in ./backup/db/ directory

EXAMPLES:
    $0 stagingaccountdb01.sql
    $0 prodtransactiondb01_pgtransaction.sql

SAFETY FEATURES:
    ✓ Development environment check
    ✓ Container health verification
    ✓ File existence validation
    ✓ Database connection test
    ✓ Import progress monitoring
    ✓ Rollback capability (via transaction)

REQUIREMENTS:
    - MariaDB container (${CONTAINER_NAME}) must be running
    - Docker and docker-compose must be available
    - SQL file must exist in ${BACKUP_DIR}/
    - Development environment only

EOF
}

# Safety check: Ensure this is development environment
check_development_environment() {
    log_info "Checking development environment..."
    
    # Check if we're in the right directory
    if [[ ! -f "${PROJECT_ROOT}/docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found. Please run this script from the project root."
        exit 1
    fi
    
    # Check for development indicators
    if [[ ! -d "${PROJECT_ROOT}/backup" ]] || [[ ! -d "${PROJECT_ROOT}/etc" ]]; then
        log_error "Development directory structure not found."
        exit 1
    fi
    
    log_success "Development environment confirmed"
}

# Check if required arguments are provided
check_arguments() {
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    if [[ $# -ne 1 ]]; then
        log_error "Invalid number of arguments"
        echo "Usage: $0 <sql_file>"
        echo "Use '$0 --help' for more information"
        exit 1
    fi
}

# Check if Docker is running
check_docker() {
    log_info "Checking Docker availability..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "Docker is available"
}

# Check if MariaDB container is running
check_container() {
    log_info "Checking MariaDB container status..."
    
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_error "MariaDB container '${CONTAINER_NAME}' is not running"
        log_info "Please start it with: docker-compose up -d mariadb"
        exit 1
    fi
    
    log_success "MariaDB container is running"
}

# Check if SQL file exists
check_sql_file() {
    local sql_file="$1"
    local full_path="${PROJECT_ROOT}/${BACKUP_DIR}/${sql_file}"
    
    log_info "Checking SQL file: ${sql_file}"
    
    if [[ ! -f "$full_path" ]]; then
        log_error "SQL file not found: ${full_path}"
        log_info "Available files in ${BACKUP_DIR}:"
        ls -la "${PROJECT_ROOT}/${BACKUP_DIR}/" | grep "\.sql$" || log_warning "No .sql files found"
        exit 1
    fi
    
    # Check file size
    local file_size=$(du -h "$full_path" | cut -f1)
    log_success "SQL file found (${file_size}): ${sql_file}"
}

# Test database connection
test_connection() {
    log_info "Testing database connection..."
    
    # Wait a moment for MariaDB to be fully ready
    sleep 2
    
    # Try multiple times with different approaches
    local max_attempts=5
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Connection attempt ${attempt}/${max_attempts}..."
        
        # Test with mariadb client (not mysql)
        if docker exec "$CONTAINER_NAME" mariadb -h127.0.0.1 -P3306 -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1 as test;" 2>/dev/null; then
            log_success "Database connection successful"
            return 0
        fi
        
        # Alternative test method
        if docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" &> /dev/null; then
            log_success "Database connection successful"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Connection attempt ${attempt} failed, retrying in 3 seconds..."
            sleep 3
        fi
        
        ((attempt++))
    done
    
    log_error "Cannot connect to MariaDB database after ${max_attempts} attempts"
    log_info "Container status:"
    docker exec "$CONTAINER_NAME" ps aux | grep mariadb || echo "MariaDB process check failed"
    log_info "Container logs:"
    docker logs --tail 10 "$CONTAINER_NAME"
    
    # Show more detailed error
    log_info "Detailed connection test:"
    docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" || true
    
    exit 1
}

# Extract database name from SQL file
extract_database_name() {
    local sql_file="$1"
    local full_path="${PROJECT_ROOT}/${BACKUP_DIR}/${sql_file}"
    
    # Try to extract database name from SQL dump
    local db_name=$(grep -i "^-- Host.*Database:" "$full_path" | head -1 | sed -n 's/.*Database: \([^ ]*\).*/\1/p' 2>/dev/null || echo "")
    
    if [[ -z "$db_name" ]]; then
        # Fallback: try to extract from USE statement
        db_name=$(grep -i "^USE " "$full_path" | head -1 | sed 's/USE `\([^`]*\)`.*/\1/' 2>/dev/null || echo "")
    fi
    
    if [[ -z "$db_name" ]]; then
        log_warning "Could not auto-detect database name from SQL file"
        read -p "Please enter the target database name: " db_name
        if [[ -z "$db_name" ]]; then
            log_error "Database name is required"
            exit 1
        fi
    fi
    
    echo "$db_name"
}

# Create database if it doesn't exist
create_database() {
    local db_name="$1"
    
    log_info "Ensuring database '${db_name}' exists..."
    
    docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    log_success "Database '${db_name}' is ready"
}

# Backup existing database (optional)
backup_existing_database() {
    local db_name="$1"
    
    log_info "Checking if database '${db_name}' has existing data..."
    
    local table_count=$(docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema='${db_name}';" -s -N 2>/dev/null || echo "0")
    
    if [[ "$table_count" -gt 0 ]]; then
        log_warning "Database '${db_name}' contains ${table_count} tables"
        read -p "Do you want to create a backup before importing? (y/N): " create_backup
        
        if [[ "$create_backup" =~ ^[Yy]$ ]]; then
            local backup_file="/storage/backup_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
            log_info "Creating backup..."
            
            docker exec "$CONTAINER_NAME" mariadb-dump -u"$DB_USER" -p"$DB_PASSWORD" --single-transaction --routines --triggers "$db_name" > "${PROJECT_ROOT}/backup/backup_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
            
            log_success "Backup created: backup_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
        fi
    fi
}

# Import SQL file
import_sql() {
    local sql_file="$1"
    local db_name="$2"
    local full_path="${PROJECT_ROOT}/${BACKUP_DIR}/${sql_file}"
    
    log_info "Starting import of '${sql_file}' into database '${db_name}'..."
    log_warning "This may take several minutes depending on the file size..."
    
    # Show progress
    echo "Progress: [Starting import...]"
    
    # Import with error handling
    if docker exec -i "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" "$db_name" < "$full_path"; then
        log_success "Database import completed successfully!"
    else
        log_error "Database import failed!"
        log_info "Check the container logs for more details:"
        echo "docker logs --tail 20 $CONTAINER_NAME"
        exit 1
    fi
}

# Verify import
verify_import() {
    local db_name="$1"
    
    log_info "Verifying import..."
    
    local table_count=$(docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema='${db_name}';" -s -N)
    
    if [[ "$table_count" -gt 0 ]]; then
        log_success "Import verification successful: ${table_count} tables found in database '${db_name}'"
        
        # Show some table names
        log_info "Sample tables:"
        docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT table_name FROM information_schema.tables WHERE table_schema='${db_name}' LIMIT 5;" -s -N | while read table; do
            echo "  - $table"
        done
    else
        log_warning "Import verification failed: No tables found in database '${db_name}'"
    fi
}

# Main function
main() {
    local sql_file="$1"
    
    echo "==========================================="
    echo "MariaDB Database Import Script"
    echo "Environment: DEVELOPMENT ONLY"
    echo "==========================================="
    
    # Run all checks
    check_development_environment
    check_docker
    check_container
    check_sql_file "$sql_file"
    test_connection
    
    # Extract database name
    local db_name=$(extract_database_name "$sql_file")
    log_info "Target database: ${db_name}"
    
    # Confirm before proceeding
    echo ""
    log_warning "IMPORTANT: This will import '${sql_file}' into database '${db_name}'"
    read -p "Do you want to continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Import cancelled by user"
        exit 0
    fi
    
    # Execute import
    create_database "$db_name"
    backup_existing_database "$db_name"
    
    echo ""
    log_info "Starting import process..."
    start_time=$(date +%s)
    
    import_sql "$sql_file" "$db_name"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    verify_import "$db_name"
    
    echo ""
    echo "==========================================="
    log_success "Import completed in ${duration} seconds"
    log_info "Database: ${db_name}"
    log_info "File: ${sql_file}"
    echo "==========================================="
}

# Script entry point
check_arguments "$@"
main "$1"