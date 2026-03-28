#!/bin/bash
# PostgreSQL initialization script for Temporal
# This script prepares the database for Temporal usage

set -e

# Default values
DB_USER="${POSTGRES_USER:-temporal}"
DB_PASSWORD="${POSTGRES_PASSWORD:-temporal}"
DB_NAME="${POSTGRES_DB:-temporal}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_HOST="${POSTGRES_HOST:-pc_postgres}"

echo "Initializing Temporal PostgreSQL database..."
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"

# Create database and user if they don't exist
PGPASSWORD=root psql -h "$DB_HOST" -U postgres -p "$DB_PORT" <<EOF
DO
\$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
    CREATE DATABASE $DB_NAME;
    RAISE NOTICE 'Database $DB_NAME created';
  END IF;
END
\$\$;

DO
\$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DB_USER') THEN
    CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    RAISE NOTICE 'User $DB_USER created';
  END IF;
END
\$\$;

-- Grant privileges
ALTER USER $DB_USER CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Connect to temporal database and create schema
\c $DB_NAME postgres

-- Create timeline table if it doesn't exist
CREATE TABLE IF NOT EXISTS executions (
  namespace_id BYTEA NOT NULL,
  workflow_id VARCHAR(255) NOT NULL,
  run_id BYTEA NOT NULL,
  event_id BIGINT NOT NULL,
  event_type SMALLINT,
  event_time TIMESTAMP,
  version BIGINT,
  task_generator_version BIGINT NOT NULL DEFAULT 0,
  task_generator_partition_count INT,
  PRIMARY KEY (namespace_id, workflow_id, run_id, event_id)
);

CREATE INDEX IF NOT EXISTS ix_open_workflows 
  ON executions (namespace_id, workflow_id) 
  WHERE event_type IS NULL;

-- Grant all privileges to temporal user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;

EOF

echo "Temporal PostgreSQL initialization complete!"
