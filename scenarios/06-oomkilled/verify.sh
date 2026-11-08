#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-06

check "Deployment image-resizer rolls out and is Available" rollout_ok "$NS" image-resizer
check "WORKING_SET_MB is still 150" \
  equals "$(jp "$NS" deploy/image-resizer '{.spec.template.spec.containers[0].env[?(@.name=="WORKING_SET_MB")].value}')" "150"
check "A memory limit is still set" \
  not_empty "$(jp "$NS" deploy/image-resizer '{.spec.template.spec.containers[0].resources.limits.memory}')"
check "App reports its buffer is ready" \
  bash -c "kubectl -n $NS logs deploy/image-resizer | grep -q 'buffer ready'"
check "Pod has zero restarts" no_restarts "$NS" app=image-resizer

finish
