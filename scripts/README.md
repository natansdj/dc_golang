# Database Import Scripts

This directory contains scripts for safely importing SQL database dumps into the MariaDB container in development environment.

## Scripts

### 1. `import-db.sh` (Recommended)
**Full-featured import script with comprehensive safety checks**

#### Features:
- ✅ Development environment verification
- ✅ Container health checks
- ✅ File validation
- ✅ Database connection testing
- ✅ Auto-detection of database name
- ✅ Optional backup before import
- ✅ Import progress monitoring
- ✅ Post-import verification
- ✅ Detailed logging and error handling

#### Usage:
```bash
# From project root directory
./scripts/import-db.sh <sql_file>

# Examples:
./scripts/import-db.sh stagingaccountdb01.sql
./scripts/import-db.sh prodtransactiondb01_pgtransaction.sql
```

#### Help:
```bash
./scripts/import-db.sh --help
```

### 2. `quick-import.sh`
**Simplified script for quick imports without extensive checks**

#### Features:
- ✅ Basic file and container validation
- ✅ Auto-detection of database name
- ✅ Fast import process
- ✅ Minimal logging

#### Usage:
```bash
# From project root directory
./scripts/quick-import.sh <sql_file> [database_name]

# Examples:
./scripts/quick-import.sh stagingaccountdb01.sql
./scripts/quick-import.sh stagingaccountdb01.sql PaycloudAccount
```

## Prerequisites

Before using these scripts, ensure:

1. **MariaDB Container Running**:
   ```bash
   docker-compose up -d mariadb
   ```

2. **Container Health Check**:
   ```bash
   docker ps | grep pc_mariadb
   ```

3. **SQL Files Available**:
   - Files should be in `./backup/db/` directory
   - Supported format: MariaDB/MySQL dump files (.sql)

## Available SQL Files

Current backup files in `./backup/db/`:
- `stagingaccountdb01.sql`
- `prodaccountdb01_paycloudaccount.sql`
- `prodtransactiondb01_pgconfig.sql`
- `prodtransactiondb01_pgmerchant.sql`
- `prodtransactiondb01_pgtransaction.sql`
- `stagingtransactiondb01_pgconfig.sql`
- `stagingtransactiondb01_pgmerchant.sql`
- `stagingtransactiondb01_pgtransaction.sql`

## Safety Features

### Development Environment Only
- Scripts verify they're running in development environment
- Checks for docker-compose.yml and development directory structure
- **DO NOT USE IN PRODUCTION**

### Database Safety
- Creates database if it doesn't exist
- Optional backup before import (recommended for existing data)
- Transactional import where possible
- Post-import verification

### Error Handling
- Comprehensive error checking at each step
- Descriptive error messages with suggested solutions
- Safe exit on any failure

## Examples

### Complete Import with Safety Checks
```bash
# Use the full-featured script
./scripts/import-db.sh stagingaccountdb01.sql

# The script will:
# 1. Verify development environment
# 2. Check MariaDB container status
# 3. Validate SQL file exists
# 4. Test database connection
# 5. Auto-detect target database name (PaycloudAccount)
# 6. Offer to backup existing data
# 7. Import the SQL file
# 8. Verify import success
```

### Quick Import
```bash
# Use the simplified script for speed
./scripts/quick-import.sh stagingaccountdb01.sql

# Faster execution with basic safety checks
```

### Manual Database Name
```bash
# Specify database name explicitly
./scripts/quick-import.sh myfile.sql MyCustomDatabase
```

## Troubleshooting

### Container Not Running
```bash
# Start MariaDB container
docker-compose up -d mariadb

# Check logs if issues
docker-compose logs mariadb
```

### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### File Not Found
```bash
# List available SQL files
ls -la backup/db/*.sql
```

### Import Errors
```bash
# Check container logs
docker logs pc_mariadb

# Test database connection
docker exec pc_mariadb mysql -uroot -proot -e "SELECT 1;"
```

## Configuration

Scripts use these default configurations:
- **Container Name**: `pc_mariadb`
- **Database User**: `root`
- **Database Password**: `root`
- **Backup Directory**: `./backup/db/`

To modify these settings, edit the scripts directly or create environment-specific versions.

## Security Notes

⚠️ **Development Environment Only**
- These scripts are designed for development use only
- Database credentials are hardcoded for development convenience
- No encryption or secure authentication mechanisms
- Never use these scripts in production environments

## Support

For issues or questions:
1. Check script help: `./scripts/import-db.sh --help`
2. Verify prerequisites are met
3. Check MariaDB container logs
4. Ensure SQL file format is compatible