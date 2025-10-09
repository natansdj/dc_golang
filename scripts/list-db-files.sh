#!/bin/bash

#############################################################################
# List Available Database Files
# 
# Description: Lists all available SQL files in the backup directory
# Usage: ./list-db-files.sh
#############################################################################

BACKUP_DIR="./backup/db"
PROJECT_ROOT="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Available Database Files${NC}"
echo "=================================================="
echo "Location: ${BACKUP_DIR}/"
echo ""

if [[ ! -d "${PROJECT_ROOT}/${BACKUP_DIR}" ]]; then
    echo -e "${YELLOW}Warning: Backup directory not found: ${PROJECT_ROOT}/${BACKUP_DIR}${NC}"
    exit 1
fi

# Check if any .sql files exist
if ! ls "${PROJECT_ROOT}/${BACKUP_DIR}/"*.sql 1> /dev/null 2>&1; then
    echo "No SQL files found in ${BACKUP_DIR}/"
    exit 0
fi

# List files with details
echo -e "${GREEN}SQL Files:${NC}"
cd "${PROJECT_ROOT}/${BACKUP_DIR}" || exit 1

for file in *.sql; do
    if [[ -f "$file" ]]; then
        size=$(du -h "$file" | cut -f1)
        modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
        
        # Try to extract database name
        db_name=$(grep -i "^-- Host.*Database:" "$file" | head -1 | sed -n 's/.*Database: \([^ ]*\).*/\1/p' 2>/dev/null || echo "Unknown")
        
        printf "  %-35s | %-8s | %-16s | %s\n" "$file" "$size" "$modified" "$db_name"
    fi
done

echo ""
echo "Usage Examples:"
echo "  ./scripts/import-db.sh stagingaccountdb01.sql"
echo "  ./scripts/quick-import.sh prodtransactiondb01_pgtransaction.sql"