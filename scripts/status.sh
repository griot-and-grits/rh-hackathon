#!/bin/bash
# Griot & Grits - Check Status of All Services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_running() { echo -e "  ${GREEN}[RUNNING]${NC} $1"; }
print_stopped() { echo -e "  ${RED}[STOPPED]${NC} $1"; }
print_status() { echo -e "${BLUE}[*]${NC} $1"; }

# Detect container runtime
detect_runtime() {
    if [ -f "$ROOT_DIR/.container-runtime" ]; then
        RUNTIME=$(cat "$ROOT_DIR/.container-runtime")
        if command -v "$RUNTIME" &> /dev/null; then
            echo "$RUNTIME"
            return
        fi
    fi
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

RUNTIME=$(detect_runtime)

# Container names
MONGO_CONTAINER="gng-mongodb"
MINIO_CONTAINER="gng-minio"

echo ""
echo "=========================================="
echo "  Griot & Grits - Service Status"
echo "=========================================="
echo ""

# Container runtime
print_status "Container Runtime:"
if [ -n "$RUNTIME" ]; then
    echo -e "  ${GREEN}[OK]${NC} $RUNTIME"
else
    echo -e "  ${RED}[NOT FOUND]${NC} No Podman or Docker"
fi

echo ""

# Infrastructure Services
print_status "Infrastructure Services:"

if [ -n "$RUNTIME" ]; then
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MONGO_CONTAINER}$"; then
        print_running "MongoDB     → mongodb://localhost:27017"
    else
        print_stopped "MongoDB"
    fi

    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MINIO_CONTAINER}$"; then
        print_running "MinIO       → http://localhost:9000 (console: 9001)"
    else
        print_stopped "MinIO"
    fi
else
    print_stopped "MongoDB (no runtime)"
    print_stopped "MinIO (no runtime)"
fi

echo ""

# Application Services
print_status "Application Services:"

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_running "Backend     → http://localhost:8000"
else
    print_stopped "Backend"
fi

# Check if frontend is running
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    print_running "Frontend    → http://localhost:3000"
else
    print_stopped "Frontend"
fi

echo ""

# Volumes
if [ -n "$RUNTIME" ]; then
    print_status "Data Volumes:"
    if $RUNTIME volume ls --format '{{.Name}}' 2>/dev/null | grep -q "gng-mongodb-data"; then
        echo "  - gng-mongodb-data (MongoDB)"
    fi
    if $RUNTIME volume ls --format '{{.Name}}' 2>/dev/null | grep -q "gng-minio-data"; then
        echo "  - gng-minio-data (MinIO)"
    fi
fi

echo ""
