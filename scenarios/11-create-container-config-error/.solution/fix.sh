#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-11 patch deploy payments --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/secretKeyRef/key","value":"db-password"},
  {"op":"replace","path":"/spec/template/spec/containers/0/env/1/valueFrom/configMapKeyRef/name","value":"payment-config"}
]'
