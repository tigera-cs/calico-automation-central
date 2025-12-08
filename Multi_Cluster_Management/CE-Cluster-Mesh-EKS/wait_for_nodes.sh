#!/bin/bash
# wait-for-nodes.sh
# Waits until all nodes are Ready
# Usage: ./wait-for-nodes.sh [timeout_seconds]

set -euo pipefail

TIMEOUT=${1:-120}  # Default 120 seconds
INTERVAL=5
ELAPSED=0

echo "Waiting for all nodes to be Ready (timeout: ${TIMEOUT}s)..."

while (( ELAPSED < TIMEOUT )); do
  # Count Ready nodes
  READY_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready" {count++} END {print count+0}')
  TOTAL_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)

  if (( READY_COUNT == TOTAL_COUNT && TOTAL_COUNT > 0 )); then
    echo "All $READY_COUNT nodes are Ready!"
    exit 0
  else
    echo "[$ELAPSED/$TIMEOUT] $READY_COUNT/$TOTAL_COUNT nodes Ready..."
  fi

  sleep $INTERVAL
  (( ELAPSED += INTERVAL ))
done

echo "TIMEOUT: Not all nodes became Ready after ${TIMEOUT}s"
kubectl get nodes
exit 1