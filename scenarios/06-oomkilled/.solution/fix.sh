#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-06 set resources deploy/image-resizer \
  --requests=memory=192Mi --limits=memory=256Mi
