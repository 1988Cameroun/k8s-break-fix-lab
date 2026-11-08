#!/usr/bin/env bash
# Runs after manifests.yaml: wait for the good v1, then push a broken v2.
set -euo pipefail
NS=lab-12

echo "Waiting for v1 to roll out..."
kubectl -n "$NS" rollout status deploy/web --timeout=180s >/dev/null

echo "Releasing v2..."
kubectl -n "$NS" set image deploy/web nginx=nginx:1.27.99-alpine >/dev/null
# Annotate after the image change: the controller copies the Deployment's annotations
# onto the *current* ReplicaSet, so annotating first would relabel v1's history.
kubectl -n "$NS" annotate deploy/web --overwrite \
  kubernetes.io/change-cause="v2: bump nginx to 1.27.99" >/dev/null

echo "Waiting for the pipeline to give up on v2 (about a minute)..."
kubectl -n "$NS" rollout status deploy/web --timeout=90s >/dev/null 2>&1 || true
