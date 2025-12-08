#!/bin/bash

# Wait until Tigera API Server is Available
# Exits 0 on success, 1 on timeout

set -euo pipefail

TIMEOUT=${1:-300}  # Default 5 minutes
INTERVAL=30
ELAPSED=0

echo "Waiting for Tigera API Server to be Available (timeout: ${TIMEOUT}s)..."

while (( ELAPSED < TIMEOUT )); do
    # Get status of apiserver condition "Available"
    STATUS=$(kubectl get tigerastatus apiserver -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")

    if [[ "$STATUS" == "True" ]]; then
        echo "API Server is Available!"
        exit 0
    else
        echo "[$ELAPSED/$TIMEOUT] API Server status: $STATUS, retrying in $INTERVAL seconds..."
        sleep $INTERVAL
        (( ELAPSED += INTERVAL ))
    fi
done

echo "TIMEOUT: API Server did not become Available after ${TIMEOUT}s"
kubectl get tigerastatus apiserver -o yaml
exit 1
