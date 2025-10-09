#!/bin/bash

#############################################################################
# Quick Database Import Script - Simple Version
# 
# Description: Simplified version for quick imports without extensive checks
# Usage: ./quick-import.sh <sql_file> [database_name]
# Example: ./quick-import.sh stagingaccountdb01.sql PaycloudAccount
#############################################################################

set -e

# Configuration
CONTAINER_NAME="pc_mariadb"
DB_USER="root"
DB_PASSWORD="root"
BACKUP_DIR="../backup/db"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <sql_file> [database_name]"
    echo "Example: $0 stagingaccountdb01.sql PaycloudAccount"
    exit 1
fi

SQL_FILE="$1"
DB_NAME="${2:-}"

# Check if file exists
if [[ ! -f "${BACKUP_DIR}/${SQL_FILE}" ]]; then
    echo -e "${RED}Error: File ${BACKUP_DIR}/${SQL_FILE} not found${NC}"
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: Container $CONTAINER_NAME is not running${NC}"
    exit 1
fi

# Auto-detect database name if not provided
if [[ -z "$DB_NAME" ]]; then
    DB_NAME=$(grep -i "^-- Host.*Database:" "${BACKUP_DIR}/${SQL_FILE}" | head -1 | sed -n 's/.*Database: \([^ ]*\).*/\1/p' 2>/dev/null || echo "")
    if [[ -z "$DB_NAME" ]]; then
        echo -e "${YELLOW}Warning: Could not auto-detect database name${NC}"
        read -p "Enter database name: " DB_NAME
    fi
fi

echo -e "${GREEN}Importing ${SQL_FILE} into database ${DB_NAME}...${NC}"

# Create database if it doesn't exist
docker exec "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import the SQL file
if docker exec -i "$CONTAINER_NAME" mariadb -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "${BACKUP_DIR}/${SQL_FILE}"; then
    echo -e "${GREEN}Import completed successfully!${NC}"
else
    echo -e "${RED}Import failed!${NC}"
    exit 1
fi