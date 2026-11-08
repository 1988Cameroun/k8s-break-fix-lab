#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-01

check "Deployment inventory-api rolls out and is Available" rollout_ok "$NS" inventory-api
check "Container image is unchanged (busybox:1.36)" \
  equals "$(jp "$NS" deploy/inventory-api '{.spec.template.spec.containers[0].image}')" "busybox:1.36"
check "ConfigMap app-config is still mounted" \
  equals "$(jp "$NS" deploy/inventory-api '{.spec.template.spec.volumes[0].configMap.name}')" "app-config"
check "App logs show the config was loaded" \
  bash -c "kubectl -n $NS logs deploy/inventory-api | grep -q 'loaded config'"
check "Pods have zero restarts" no_restarts "$NS" app=inventory-api

finish
