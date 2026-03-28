#!/bin/bash
# Temporal & Docker Setup Verification Script
# Run this to verify all components are properly configured

set -e

WORKSPACE_DIR="/Users/natan/docker/dc_golang"
PROJECT_NAME="dc_golang"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Temporal Setup & Dockerfile Verification                      ║"
echo "║  Workspace: $WORKSPACE_DIR"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED=0

# Function to check file existence
check_file() {
    if [ -f "$1" ]; then
        echo "${GREEN}✓${NC} $1"
        return 0
    else
        echo "${RED}✗${NC} $1 NOT FOUND"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Function to check directory existence
check_dir() {
    if [ -d "$1" ]; then
        echo "${GREEN}✓${NC} $1/"
        return 0
    else
        echo "${RED}✗${NC} $1/ NOT FOUND"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "1. Checking Temporal Configuration Files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_dir "$WORKSPACE_DIR/etc/temporal"
check_file "$WORKSPACE_DIR/etc/temporal/README.md"
check_file "$WORKSPACE_DIR/etc/temporal/dynamic.yaml"
check_file "$WORKSPACE_DIR/etc/temporal/temporal.env"
check_file "$WORKSPACE_DIR/etc/temporal/init-postgres.sh"
echo ""

echo "2. Checking Updated Dockerfiles..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "$WORKSPACE_DIR/Dockerfile"
check_file "$WORKSPACE_DIR/Dockerfile.example"
echo ""

echo "3. Checking Docker Compose Configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "$WORKSPACE_DIR/docker-compose.pycd.yml"

# Validate docker-compose syntax
echo ""
echo "4. Validating docker-compose.pycd.yml syntax..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v docker-compose &> /dev/null; then
    if docker-compose -f "$WORKSPACE_DIR/docker-compose.pycd.yml" config -q 2>/dev/null; then
        echo "${GREEN}✓${NC} docker-compose.pycd.yml is valid"
    else
        echo "${RED}✗${NC} docker-compose.pycd.yml has validation errors"
        FAILED=$((FAILED + 1))
    fi
else
    echo "${YELLOW}⚠${NC} docker-compose not found, skipping validation"
fi
echo ""

echo "5. Checking Docker Network..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v docker &> /dev/null; then
    if docker network inspect dev &> /dev/null; then
        echo "${GREEN}✓${NC} Docker network 'dev' exists"
    else
        echo "${YELLOW}⚠${NC} Docker network 'dev' not found"
        echo "   Run: docker network create dev"
    fi
else
    echo "${YELLOW}⚠${NC} docker not found, skipping check"
fi
echo ""

echo "6. Checking Documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "$WORKSPACE_DIR/TEMPORAL_SETUP_SUMMARY.md"
echo ""

echo "7. Dockerfile Content Verification..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Dockerfile for Go 1.24
if grep -q "ARG GO_VERSION=1.24" "$WORKSPACE_DIR/Dockerfile"; then
    echo "${GREEN}✓${NC} Dockerfile uses Go 1.24"
else
    echo "${RED}✗${NC} Dockerfile does not use Go 1.24"
    FAILED=$((FAILED + 1))
fi

# Check Dockerfile.example for multi-stage
if grep -q "FROM golang" "$WORKSPACE_DIR/Dockerfile.example" && grep -q "AS builder" "$WORKSPACE_DIR/Dockerfile.example"; then
    echo "${GREEN}✓${NC} Dockerfile.example uses multi-stage build"
else
    echo "${RED}✗${NC} Dockerfile.example does not use multi-stage build"
    FAILED=$((FAILED + 1))
fi

# Check for security features
if grep -q "appuser" "$WORKSPACE_DIR/Dockerfile"; then
    echo "${GREEN}✓${NC} Dockerfile has non-root user"
else
    echo "${RED}✗${NC} Dockerfile missing non-root user"
    FAILED=$((FAILED + 1))
fi

# Check for development tools
if grep -q "golangci-lint\|air\|gotestsum" "$WORKSPACE_DIR/Dockerfile"; then
    echo "${GREEN}✓${NC} Dockerfile includes Go development tools"
else
    echo "${RED}✗${NC} Dockerfile missing Go development tools"
    FAILED=$((FAILED + 1))
fi
echo ""

echo "8. Docker Compose Temporal Services Check..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q "temporal:" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal server service defined"
fi

if grep -q "temporalio/server:1.30.1" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal Server version 1.30.1 specified"
fi

if grep -q "temporal-ui:" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal UI service defined"
fi

if grep -q "temporalio/ui:2.47.2" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal UI version 2.47.2 specified"
fi

if grep -q "pc_temporal" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal container names configured"
fi

if grep -q "7233" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal gRPC port (7233) configured"
fi

if grep -q "8081" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} Temporal UI port (8081) configured"
fi

if grep -q "postgres" "$WORKSPACE_DIR/docker-compose.pycd.yml" && grep -q "temporal:" "$WORKSPACE_DIR/docker-compose.pycd.yml"; then
    echo "${GREEN}✓${NC} PostgreSQL dependency configured for Temporal"
fi
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
if [ $FAILED -eq 0 ]; then
    echo "║  ${GREEN}✓ ALL CHECKS PASSED${NC}                                              ║"
else
    echo "║  ${RED}✗ $FAILED CHECK(S) FAILED${NC}                                        ║"
fi
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📚 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Review: $WORKSPACE_DIR/TEMPORAL_SETUP_SUMMARY.md"
echo "2. Read: $WORKSPACE_DIR/etc/temporal/README.md"
echo "3. Create network: docker network create dev"
echo "4. Start services: docker-compose -f docker-compose.pycd.yml up -d temporal temporal-ui"
echo "5. Access UI: http://localhost:8081"
echo ""

exit $FAILED
