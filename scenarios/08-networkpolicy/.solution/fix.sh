#!/usr/bin/env bash
# Reference fix used by CI to prove the scenario is solvable.
set -euo pipefail
kubectl -n lab-08 patch networkpolicy allow-web-to-api --type=json -p '[
  {"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"tier":"frontend"}},
  {"op":"replace","path":"/spec/ingress/0/ports/0/port","value":80}
]'
