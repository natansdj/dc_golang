# Quick Reference: Temporal & Docker Setup

## 🚀 Start Temporal Services

```bash
cd /Users/natan/docker/dc_golang

# Ensure network exists
docker network create dev

# Start all infrastructure (PostgreSQL required for Temporal)
docker-compose -f docker-compose.pycd.yml up -d postgres temporal temporal-ui

# View logs
docker-compose -f docker-compose.pycd.yml logs -f temporal
docker-compose -f docker-compose.pycd.yml logs -f temporal-ui
```

## 🎯 Access Temporal UI

**URL**: http://localhost:8081

## 🔌 Connect from Go Services

```go
import "github.com/temporalio/sdk-go/client"

c, err := client.Dial(client.Options{
    HostPort: "localhost:7233",
})
if err != nil {
    panic(err)
}
defer c.Close()
```

## 🔌 Connect from Node.js/TypeScript

```typescript
import { WorkflowClient } from '@temporalio/client';

const client = new WorkflowClient({
    connection: {
        address: 'localhost:7233'
    }
});
```

## 📁 File Structure

```
/Users/natan/docker/dc_golang/
├── docker-compose.pycd.yml              # ✅ Updated with Temporal
├── Dockerfile                           # ✅ Go 1.24 + improvements
├── Dockerfile.example                   # ✅ Multi-stage build
├── TEMPORAL_SETUP_SUMMARY.md           # Complete documentation
├── scripts/verify-temporal-setup.sh    # Verification script
└── etc/temporal/                        # Temporal configuration
    ├── README.md                        # Detailed guide
    ├── dynamic.yaml                     # Server config
    ├── temporal.env                     # Environment vars
    └── init-postgres.sh                 # PostgreSQL init
```

## 📊 Services Overview

| Service | Version | Port | Container |
|---------|---------|------|-----------|
| Temporal Server | 1.30.1 | 7233 | pc_temporal |
| Temporal UI | 2.47.2 | 8081 | pc_temporal_ui |
| PostgreSQL | 16 | 5432 | pc_postgres |

## 🔐 Default Credentials

| Service | User | Password |
|---------|------|----------|
| Temporal DB | temporal | temporal |
| PostgreSQL | root | root |

## ✅ Dockerfile Improvements

**Dockerfile (Go 1.24)**:
- ✓ Updated from 1.22 to 1.24
- ✓ Go dev tools: air, golangci-lint, gotestsum
- ✓ DB clients: postgresql-client, mysql-client
- ✓ Non-root user (appuser)
- ✓ Health checks
- ✓ Proper timezone handling

**Dockerfile.example (Advanced)**:
- ✓ Multi-stage build (builder + runtime)
- ✓ Minimal runtime image
- ✓ Build-time version linking
- ✓ Optimized layer caching (go.mod first)
- ✓ tini init system
- ✓ Security: non-root user, dropped capabilities
- ✓ Health checks
- ✓ Image labels and metadata

## 🧪 Verify Setup

```bash
# Run verification script
./scripts/verify-temporal-setup.sh

# OR manually
docker-compose -f docker-compose.pycd.yml config -q
docker-compose -f docker-compose.pycd.yml ps
```

## 🛑 Stop Services

```bash
docker-compose -f docker-compose.pycd.yml down

# Remove all data (WARNING: deletes databases)
docker-compose -f docker-compose.pycd.yml down -v
```

## 📚 Documentation

- **Setup & Troubleshooting**: See [etc/temporal/README.md](./etc/temporal/README.md)
- **Complete Summary**: See [TEMPORAL_SETUP_SUMMARY.md](./TEMPORAL_SETUP_SUMMARY.md)
- **Temporal Docs**: https://docs.temporal.io/

## 🔧 Common Tasks

### Create a Workflow (Go)

```go
type MyWorkflow struct{}

func (w *MyWorkflow) Execute(ctx workflow.Context) error {
    activity := &MyActivity{}
    var result string
    err := workflow.ExecuteActivity(ctx, activity.DoSomething, "arg").Get(ctx, &result)
    return err
}
```

### Register Workflow

```go
workerOptions := worker.Options{
    Identity:           "worker-1",
    MaxConcurrentActivityExecutionSize: 100,
}
w := worker.New(c, "default", workerOptions)
w.RegisterWorkflow(MyWorkflow)
w.RegisterActivity(MyActivity)
```

### View Metrics

```bash
curl http://localhost:9090/metrics | grep temporal
```

## 🆘 Troubleshooting

**Temporal won't start?**
- Check PostgreSQL is running: `docker ps | grep postgres`
- Check logs: `docker-compose -f docker-compose.pycd.yml logs temporal`

**Can't connect from client?**
- Verify port: `docker ps | grep temporal`
- Test: `curl localhost:7233` (should fail gracefully)
- Check network: `docker network inspect dev`

**UI not loading?**
- Check service: `docker-compose -f docker-compose.pycd.yml ps temporal-ui`
- Verify connection: `docker-compose -f docker-compose.pycd.yml logs temporal-ui`
- Try: http://localhost:8081 directly

## 📞 Support

For Temporal issues:
- [Temporal Docs](https://docs.temporal.io/)
- [Community Slack](https://temporal.io/slack)

For Docker/Compose issues:
- [Docker Docs](https://docs.docker.com/)
- See [AGENTS.md](./AGENTS.md) for workflow guidance
