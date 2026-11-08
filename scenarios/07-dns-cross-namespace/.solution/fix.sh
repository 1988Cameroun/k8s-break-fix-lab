#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-07 set env deploy/orders \
  PRICING_URL=http://pricing.lab-07-data.svc.cluster.local
