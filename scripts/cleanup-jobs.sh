#!/bin/bash
# Clean up old completed/failed jobs in your namespace
# Usage: ./scripts/cleanup-jobs.sh [namespace]

set -e

NAMESPACE="${1:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
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
echo "=========================================="
echo "  Cleanup Jobs - $NAMESPACE"
echo "=========================================="
echo ""

# Check if namespace exists
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    print_error "Namespace $NAMESPACE does not exist"
    exit 1
fi

# List all jobs
print_status "Current jobs in namespace:"
oc get jobs -n "$NAMESPACE" 2>/dev/null || {
    print_warning "No jobs found"
    exit 0
}

echo ""

# Count jobs
INIT_JOB_COUNT=$(oc get jobs -n "$NAMESPACE" -o name 2>/dev/null | grep -c "init-db" || echo "0")
VERIFY_JOB_COUNT=$(oc get jobs -n "$NAMESPACE" -o name 2>/dev/null | grep -c "verify-db" || echo "0")

if [ "$INIT_JOB_COUNT" -eq "0" ] && [ "$VERIFY_JOB_COUNT" -eq "0" ]; then
    print_success "No init-db or verify-db jobs to clean up"
    exit 0
fi

print_warning "Found $INIT_JOB_COUNT init-db job(s) and $VERIFY_JOB_COUNT verify-db job(s)"
echo ""

read -p "Delete all init-db and verify-db jobs? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Delete init-db jobs
if [ "$INIT_JOB_COUNT" -gt "0" ]; then
    print_status "Deleting init-db jobs..."
    oc delete jobs -l job-name=init-db -n "$NAMESPACE" 2>/dev/null || true
    oc delete job init-db -n "$NAMESPACE" 2>/dev/null || true
    print_success "Deleted init-db jobs"
fi

# Delete verify-db jobs
if [ "$VERIFY_JOB_COUNT" -gt "0" ]; then
    print_status "Deleting verify-db jobs..."
    oc delete jobs -l job-name=verify-db -n "$NAMESPACE" 2>/dev/null || true
    oc delete job verify-db -n "$NAMESPACE" 2>/dev/null || true
    print_success "Deleted verify-db jobs"
fi

echo ""
print_status "Remaining jobs:"
oc get jobs -n "$NAMESPACE" 2>/dev/null || echo "No jobs remaining"

echo ""
print_success "Cleanup complete!"
echo ""
echo "Note: Future jobs will auto-delete after completion (TTL enabled)"
echo ""
