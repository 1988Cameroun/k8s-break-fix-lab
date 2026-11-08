#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-10 patch role pod-reader --type=json -p \
  '[{"op":"replace","path":"/rules/0/verbs","value":["get","list"]}]'
