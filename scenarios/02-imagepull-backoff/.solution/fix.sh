#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-02 set image deploy/storefront nginx=nginx:1.27-alpine
