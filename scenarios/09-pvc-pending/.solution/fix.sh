#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-09 scale deploy/uploader --replicas=0
kubectl -n lab-09 wait --for=delete pod -l app=uploader --timeout=60s || true
kubectl -n lab-09 delete pvc uploads --wait=true --timeout=60s
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads
  namespace: lab-09
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
EOF
kubectl -n lab-09 scale deploy/uploader --replicas=1
