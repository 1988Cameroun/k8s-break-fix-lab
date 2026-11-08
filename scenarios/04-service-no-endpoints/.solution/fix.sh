#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-04 patch svc checkout --type=json -p '[
  {"op":"replace","path":"/spec/selector","value":{"app":"checkout","tier":"api"}},
  {"op":"replace","path":"/spec/ports/0/targetPort","value":"http"}
]'
