#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-05
P='{.spec.template.spec.containers[0].readinessProbe'

check "Deployment catalog rolls out and is Available" rollout_ok "$NS" catalog
check "3 replicas are ready" equals "$(jp "$NS" deploy/catalog '{.status.readyReplicas}')" "3"
check "Readiness probe still exists and checks /healthz" \
  equals "$(jp "$NS" deploy/catalog "$P.httpGet.path}")" "/healthz"
check "Service catalog has 3 ready endpoints" \
  equals "$(ready_endpoints "$NS" catalog)" "3"

finish
