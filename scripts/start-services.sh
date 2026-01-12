#!/bin/bash
# Griot & Grits - Start Infrastructure Services
# Starts MongoDB and MinIO in containers (Podman or Docker)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Detect container runtime
detect_runtime() {
    # Check saved preference first
    if [ -f "$ROOT_DIR/.container-runtime" ]; then
        RUNTIME=$(cat "$ROOT_DIR/.container-runtime")
        if command -v "$RUNTIME" &> /dev/null; then
            echo "$RUNTIME"
            return
        fi
    fi

    # Auto-detect
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

RUNTIME=$(detect_runtime)

if [ -z "$RUNTIME" ]; then
    print_error "No container runtime found (Podman or Docker)"
    echo "Run ./scripts/setup.sh first to install Podman"
    exit 1
fi

# Container names
MONGO_CONTAINER="gng-mongodb"
MINIO_CONTAINER="gng-minio"

# Configuration
MONGO_PORT=27017
MONGO_USER="admin"
MONGO_PASS="gngdevpass12"

MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_USER="minioadmin"
MINIO_PASS="minioadmin"
MINIO_BUCKET="artifacts"

echo ""
echo "=========================================="
echo "  Starting Griot & Grits Services"
echo "=========================================="
echo ""
print_status "Using runtime: $RUNTIME"
echo ""

# Start MongoDB
print_status "Starting MongoDB..."

if $RUNTIME ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${MONGO_CONTAINER}$"; then
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MONGO_CONTAINER}$"; then
        print_warning "MongoDB already running"
    else
        $RUNTIME start "$MONGO_CONTAINER"
        print_success "MongoDB started (existing container)"
    fi
else
    $RUNTIME run -d \
        --name "$MONGO_CONTAINER" \
        -p ${MONGO_PORT}:27017 \
        -e MONGO_INITDB_ROOT_USERNAME="$MONGO_USER" \
        -e MONGO_INITDB_ROOT_PASSWORD="$MONGO_PASS" \
        -v gng-mongodb-data:/data/db \
        mongo:latest
    print_success "MongoDB started (new container)"
fi

# Start MinIO
print_status "Starting MinIO..."

if $RUNTIME ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${MINIO_CONTAINER}$"; then
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MINIO_CONTAINER}$"; then
        print_warning "MinIO already running"
    else
        $RUNTIME start "$MINIO_CONTAINER"
        print_success "MinIO started (existing container)"
    fi
else
    $RUNTIME run -d \
        --name "$MINIO_CONTAINER" \
        -p ${MINIO_PORT}:9000 \
        -p ${MINIO_CONSOLE_PORT}:9001 \
        -e MINIO_ROOT_USER="$MINIO_USER" \
        -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
        -v gng-minio-data:/data \
        quay.io/minio/minio server /data --console-address ":9001"
    print_success "MinIO started (new container)"
fi

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 3

# Check MongoDB
if $RUNTIME exec "$MONGO_CONTAINER" mongosh --quiet --eval "db.runCommand('ping').ok" &> /dev/null; then
    print_success "MongoDB is healthy"
else
    print_warning "MongoDB may still be starting up..."
fi

# Check MinIO
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${MINIO_PORT}/minio/health/live" 2>/dev/null | grep -q "200"; then
    print_success "MinIO is healthy"

    # Try to create bucket using mc from host if available
    if command -v mc &> /dev/null; then
        mc alias set gng-local http://localhost:${MINIO_PORT} $MINIO_USER $MINIO_PASS 2>/dev/null || true
        mc mb --ignore-existing gng-local/${MINIO_BUCKET} 2>/dev/null || true
        print_success "Bucket '${MINIO_BUCKET}' ready"
    else
        print_warning "Install 'mc' (MinIO Client) to auto-create bucket, or create via console"
    fi
else
    print_warning "MinIO may still be starting up..."
fi

echo ""
echo "=========================================="
echo "  Services Started!"
echo "=========================================="
echo ""
echo "MongoDB:"
echo "  URI: mongodb://${MONGO_USER}:${MONGO_PASS}@localhost:${MONGO_PORT}/"
echo ""
echo "MinIO:"
echo "  API:     http://localhost:${MINIO_PORT}"
echo "  Console: http://localhost:${MINIO_CONSOLE_PORT}"
echo "  User:    ${MINIO_USER}"
echo "  Pass:    ${MINIO_PASS}"
echo ""
echo "To stop services: ./scripts/stop-services.sh"
echo ""
