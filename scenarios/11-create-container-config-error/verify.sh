#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-11
ENV='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")]'

check "Deployment payments rolls out and is Available" rollout_ok "$NS" payments
check "2 replicas are ready" equals "$(jp "$NS" deploy/payments '{.status.readyReplicas}')" "2"
check "DB_PASSWORD comes from the payment-db Secret" \
  equals "$(jp "$NS" deploy/payments "$ENV.valueFrom.secretKeyRef.name}")" "payment-db"
check "DB_PASSWORD is not hardcoded" \
  equals "$(jp "$NS" deploy/payments "$ENV.value}")" ""
check "App started with LOG_LEVEL=info" \
  bash -c "kubectl -n $NS logs deploy/payments | grep -q 'log level: info'"

finish
