#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-03 set resources deploy/report-generator \
  --requests=cpu=50m,memory=32Mi --limits=cpu=200m,memory=64Mi
