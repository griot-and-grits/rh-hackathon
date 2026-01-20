#!/bin/bash
# Quick test script to verify database connectivity
# Usage: ./scripts/test-db.sh [namespace]

set -e

NAMESPACE="${1:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Check if logged in
if ! oc whoami &> /dev/null; then
    print_error "Not logged into OpenShift. Run: oc login <cluster-url>"
    exit 1
fi

# Try to detect namespace from config file
if [ -z "$NAMESPACE" ] && [ -f ".openshift-config" ]; then
    source .openshift-config
fi

# If still not set, try to detect from username
if [ -z "$NAMESPACE" ]; then
    USERNAME=$(oc whoami)
    NAMESPACE="gng-${USERNAME}"
fi

echo ""
echo "Testing database in namespace: $NAMESPACE"
echo ""

# Check if namespace exists
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    print_error "Namespace $NAMESPACE does not exist"
    echo "Run: ./scripts/setup-openshift.sh"
    exit 1
fi

# Check if postgres deployment exists
if ! oc get deployment postgres -n "$NAMESPACE" &> /dev/null; then
    print_error "PostgreSQL deployment not found in namespace $NAMESPACE"
    echo "Run: ./scripts/setup-openshift.sh"
    exit 1
fi

# Check if postgres is running
print_status "Checking PostgreSQL deployment..."
if oc get deployment postgres -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' | grep -q "1"; then
    print_success "PostgreSQL is running"
else
    print_error "PostgreSQL is not running"
    echo "Check status: oc get pods -n $NAMESPACE"
    exit 1
fi

# Run a quick connectivity test
print_status "Testing database connectivity..."

cat <<'EOF' | oc run db-test-$RANDOM --rm -i --restart=Never \
  --image=registry.redhat.io/rhel9/postgresql-15 \
  -n "$NAMESPACE" -- bash

export PGPASSWORD="hackathon123"
export PGSSLMODE="disable"

# Test connection
if psql -h postgres -U hackathon -d hackathon_db -c '\q' 2>/dev/null; then
    echo "✓ Connection successful"
else
    echo "✗ Connection failed"
    exit 1
fi

# Check if users table exists
if psql -h postgres -U hackathon -d hackathon_db -c '\dt users' 2>/dev/null | grep -q users; then
    echo "✓ Users table exists"

    # Show data
    echo "✓ Sample data:"
    psql -h postgres -U hackathon -d hackathon_db -c 'SELECT * FROM users;'
else
    echo "✗ Users table not found"
    echo "Run: ./infra/postgres/deploy.sh --verify-only -n $NAMESPACE"
    exit 1
fi
EOF

echo ""
print_success "Database is working correctly!"
echo ""
echo "Connection details:"
echo "  Namespace: $NAMESPACE"
echo "  Host: postgres (or postgres.$NAMESPACE.svc.cluster.local)"
echo "  Port: 5432"
echo "  Database: hackathon_db"
echo "  User: hackathon"
echo "  Password: hackathon123"
echo ""
echo "Connection string:"
echo "  postgresql://hackathon:hackathon123@postgres:5432/hackathon_db"
echo ""
