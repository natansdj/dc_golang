# dc_golang — local Docker Compose orchestration for PayCloud-style Go stacks
#
# Override defaults:
#   make up COMPOSE_FILE=docker-compose.pycd.yml
#   make logs S=mariadb
#   DOCKER_COMPOSE=docker-compose make ps   # legacy Compose V1 binary

.DEFAULT_GOAL := help

# Docker Compose invocation (V2 plugin by default)
DOCKER_COMPOSE ?= docker compose

# Active compose file (use machine-specific variants when paths differ)
COMPOSE_FILE ?= docker-compose.yml

# Core data-plane services (matches historical `make start`)
INFRA_SERVICES := mariadb postgres mongodb redis rabbit

# Workflow + UI (PostgreSQL-backed)
TEMPORAL_SERVICES := temporal temporal-ui

# Convenience: infra + Temporal
STACK_CORE := $(INFRA_SERVICES) $(TEMPORAL_SERVICES)

DC := $(DOCKER_COMPOSE) -f $(COMPOSE_FILE)

.PHONY: help
help: ## Show this help
	@echo "dc_golang — Docker Compose helpers"
	@echo ""
	@echo "Variables: COMPOSE_FILE=$(COMPOSE_FILE)  DOCKER_COMPOSE=$(DOCKER_COMPOSE)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Compose validation & generic passthrough
# ---------------------------------------------------------------------------

.PHONY: config
config: ## Validate compose file (quiet)
	$(DC) config -q
	@echo "Compose file OK: $(COMPOSE_FILE)"

.PHONY: compose
compose: ## Passthrough: make compose ARGS="logs -f mariadb"
	@test -n "$(ARGS)" || (echo 'Usage: make compose ARGS="logs -f mariadb"'; exit 1)
	$(DC) $(ARGS)

# ---------------------------------------------------------------------------
# Lifecycle — full file vs infra-only
# ---------------------------------------------------------------------------

.PHONY: up
up: ## Start all services defined in COMPOSE_FILE (detached)
	$(DC) up -d

.PHONY: up-infra start
up-infra: ## Start MariaDB, Postgres, MongoDB, Redis, RabbitMQ
	$(DC) up -d $(INFRA_SERVICES)

start: up-infra ## Alias for up-infra (backward compatible)

.PHONY: up-stack
up-stack: ## Start infra + Temporal + Temporal UI
	$(DC) up -d $(STACK_CORE)

.PHONY: startdb
startdb: ## Start only MariaDB and PostgreSQL
	$(DC) up -d mariadb postgres

.PHONY: down
down: ## Stop and remove containers (networks/volumes preserved)
	$(DC) down

.PHONY: stop
stop: ## Stop core infra services (same set as start)
	$(DC) stop $(INFRA_SERVICES)

.PHONY: stop-all
stop-all: ## Stop every service in the compose file
	$(DC) stop

.PHONY: restart
restart: ## Restart one service: make restart S=mariadb
	@test -n "$(S)" || (echo 'Usage: make restart S=mariadb'; exit 1)
	$(DC) restart $(S)

.PHONY: recreate-infra recreate
recreate-infra: ## Force-recreate core infra containers
	$(DC) up -d --force-recreate $(INFRA_SERVICES)

recreate: recreate-infra ## Alias (replaces old docker-compose.local.yml reference)

# ---------------------------------------------------------------------------
# Observability & debugging
# ---------------------------------------------------------------------------

.PHONY: ps state
ps: ## Container status for COMPOSE_FILE
	$(DC) ps

state: ps ## Alias

.PHONY: logs
logs: ## Tail logs: make logs S=mariadb  (omit S for all)
	@if [ -n "$(S)" ]; then $(DC) logs -f --tail=200 $(S); else $(DC) logs -f --tail=200; fi

.PHONY: top
top: ## Live resource usage for compose services
	$(DC) top

.PHONY: debug-up
debug-up: ## Foreground up with Compose debug (verbose, no detach)
	COMPOSE_DEBUG=1 $(DC) up --progress=plain

.PHONY: events
events: ## Stream compose events (Ctrl+C to stop)
	$(DC) events

# ---------------------------------------------------------------------------
# Shells into data stores
# ---------------------------------------------------------------------------

.PHONY: shell-mariadb shell-postgres shell-redis shell-mongo
shell-mariadb: ## MySQL client in MariaDB container (root/root)
	$(DC) exec mariadb mariadb -uroot -proot

shell-postgres: ## psql as postgres user
	$(DC) exec postgres psql -U postgres

shell-redis: ## redis-cli in Redis container
	$(DC) exec redis redis-cli

shell-mongo: ## mongosh as root
	$(DC) exec mongodb mongosh -u root -p root

# ---------------------------------------------------------------------------
# Images — Go dev image from repo Dockerfile
# ---------------------------------------------------------------------------

.PHONY: build-go-image
build-go-image: ## Build dc_golang:1.22 (see common-services.yml)
	docker build -f Dockerfile -t dc_golang:1.22 .

.PHONY: pull
pull: ## Pull images for services in COMPOSE_FILE
	$(DC) pull

# ---------------------------------------------------------------------------
# Scripts — database & checks
# ---------------------------------------------------------------------------

.PHONY: import-db list-db quick-import verify-temporal
import-db: ## Import SQL from backup/db: make import-db FILE=dump.sql
	@test -n "$(FILE)" || (echo 'Usage: make import-db FILE=dump.sql'; exit 1)
	./scripts/import-db.sh "$(FILE)"

list-db: ## List SQL files under backup/db
	./scripts/list-db-files.sh

quick-import: ## Quick import: make quick-import FILE=dump.sql DB=MyDb
	@test -n "$(FILE)" || (echo 'Usage: make quick-import FILE=dump.sql [DB=name]'; exit 1)
	./scripts/quick-import.sh "$(FILE)" $(DB)

verify-temporal: ## Run Temporal / Docker layout checks (see script for paths)
	./scripts/verify-temporal-setup.sh

# ---------------------------------------------------------------------------
# Network prerequisite (external `dev` network)
# ---------------------------------------------------------------------------

.PHONY: network-dev
network-dev: ## Create external Docker network "dev" if missing
	@docker network inspect dev >/dev/null 2>&1 || docker network create dev
	@echo 'Network dev is ready'

# ---------------------------------------------------------------------------
# Legacy / misc
# ---------------------------------------------------------------------------

.PHONY: list
list: ## Deprecated: use `make help`
	@$(MAKE) help
