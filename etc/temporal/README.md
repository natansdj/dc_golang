# Temporal Setup Guide

## Overview

This directory contains configuration files for Temporal Server 1.30.1 and Temporal UI 2.47.2 integrated into the PayCloud development environment.

## Services

### Temporal Server (1.30.1)
- **Container**: `pc_temporal`
- **Port**: 7233 (gRPC)
- **Additional Ports**:
  - 6933: Frontend gRPC
  - 6934: History gRPC
  - 6935: Matching gRPC
  - 6936: Worker gRPC
  - 6939: Frontend HTTP
  - 9090: Metrics (Prometheus)
- **Address**: `temporal:7233`
- **Backend**: PostgreSQL (pc_postgres)

### Temporal UI (2.47.2)
- **Container**: `pc_temporal_ui`
- **Port**: 8081 (web browser)
- **URL**: `http://localhost:8081`
- **Address**: `temporal-ui`

## Files

- `dynamic.yaml` - Temporal server dynamic configuration (namespaces, retention, limits)
- `temporal.env` - Environment variables for Temporal configuration
- `init-postgres.sh` - PostgreSQL initialization script for Temporal database

## Configuration Details

### Database

Temporal uses PostgreSQL (pc_postgres) as the backend storage:
- **User**: temporal
- **Password**: temporal  
- **Database**: temporal
- **Host**: pc_postgres:5432

The PostgreSQL user and database are created automatically when the services start for the first time.

### Namespaces

Two namespaces are configured:
1. **default** - 24 hour retention
2. **dev** - 720 hour (30 days) retention

Adjust retention policies in `dynamic.yaml` as needed.

## Quick Start

### 1. Create Docker Network (if not exists)

```bash
docker network create dev
```

### 2. Start Services

```bash
cd /Users/natan/docker/dc_golang
docker-compose -f docker-compose.pycd.yml up -d postgres temporal temporal-ui
```

### 3. Verify Services

```bash
# Check services are running
docker-compose -f docker-compose.pycd.yml ps

# Check Temporal server logs
docker-compose -f docker-compose.pycd.yml logs -f temporal

# Check Temporal UI logs
docker-compose -f docker-compose.pycd.yml logs -f temporal-ui
```

### 4. Access Temporal UI

Open your browser and navigate to: **http://localhost:8081**

### 5. Test Temporal Connection

```bash
# Test gRPC connection from host
grpcurl -plaintext localhost:7233 list

# Or from another container
docker exec -it pc_temporal curl http://localhost:9090/metrics
```

## Testing Workflows

### Go Client Example

```go
package main

import (
	"context"
	"github.com/temporalio/sdk-go/client"
)

func main() {
	c, err := client.Dial(client.Options{
		HostPort: "localhost:7233",
	})
	if err != nil {
		panic(err)
	}
	defer c.Close()

	// Use client...
}
```

### Node.js Client Example

```javascript
const { WorkflowClient } = require('@temporalio/client');

const client = new WorkflowClient({
  connection: {
    address: '127.0.0.1:7233'
  }
});
```

## Metrics

Temporal exposes Prometheus metrics on port 9090:

```bash
# Get metrics
curl http://localhost:9090/metrics
```

## Customization

### Adjust Resource Limits

Edit `docker-compose.pycd.yml`:

```yaml
temporal:
  mem_limit: 1g  # Increase for high-throughput
  
temporal-ui:
  mem_limit: 512m
```

### Modify Configuration

Edit `dynamic.yaml` to adjust:
- Namespace retention policies
- Workflow/Activity concurrency limits
- Visibility database settings
- Rate limits

Changes to `dynamic.yaml` are loaded dynamically without restart.

### Enable History/Visibility Archival

Update namespace configuration in `dynamic.yaml`:

```yaml
namespaces:
  default:
    historyArchivalState: "Enabled"
    visibilityArchivalState: "Enabled"
```

## Troubleshooting

### Service won't start

1. Check PostgreSQL is running: `docker-compose -f docker-compose.pycd.yml ps`
2. Check logs: `docker-compose -f docker-compose.pycd.yml logs temporal`
3. Verify network: `docker network ls | grep dev`

### Can't connect from client

1. Ensure `temporal` is running: `docker ps | grep temporal`
2. Check port is exposed: `docker port pc_temporal`
3. Verify hostname resolution: `getent hosts 127.0.0.1`
4. For external clients, use `localhost:7233` instead of container name

### UI not loading

1. Check UI service: `docker-compose -f docker-compose.pycd.yml ps temporal-ui`
2. Verify Temporal server connection: `docker-compose -f docker-compose.pycd.yml logs temporal-ui`
3. Try accessing http://localhost:8081 directly
4. Check browser console for errors

### Database errors

1. Verify PostgreSQL: `docker-compose -f docker-compose.pycd.yml logs postgres`
2. Check Temporal user has permissions: Use `psql` admin to verify
3. Review init logs in PostgreSQL container

## Documentation Resources

- [Temporal Documentation](https://docs.temporal.io/)
- [Temporal Server Configuration](https://docs.temporal.io/self-hosted-guide/server-configuration)
- [PostgreSQL Setup](https://docs.temporal.io/self-hosted-guide/sql-database-setup)
- [Monitoring & Metrics](https://docs.temporal.io/self-hosted-guide/monitoring)

## Cleanup

### Remove Temporal containers
```bash
docker-compose -f docker-compose.pycd.yml down
```

### Remove Temporal data volume
```bash
docker volume rm temporal
```

### Remove Temporal database from PostgreSQL
```bash
docker exec -it pc_postgres psql -U postgres -c "DROP DATABASE IF EXISTS temporal;"
docker exec -it pc_postgres psql -U postgres -c "DROP USER IF EXISTS temporal;"
```
