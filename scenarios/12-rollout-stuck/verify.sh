#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-12

counts() {
  jp "$NS" deploy/web '{.spec.replicas}/{.status.updatedReplicas}/{.status.readyReplicas}/{.status.availableReplicas}'
}
progress_reason() {
  jp "$NS" deploy/web '{.status.conditions[?(@.type=="Progressing")].reason}'
}
image_not_broken() {
  [[ "$(jp "$NS" deploy/web '{.spec.template.spec.containers[0].image}')" != *1.27.99* ]]
}
deployment_not_recreated() {
  # setup.sh produced at least two revisions; a deleted/recreated Deployment starts at 1.
  (( $(jp "$NS" deploy/web '{.metadata.annotations.deployment\.kubernetes\.io/revision}') >= 2 ))
}

check "Rollout of web is complete" rollout_ok "$NS" web
check "3/3 replicas updated, ready and available" equals "$(counts)" "3/3/3/3"
check "Deployment reports NewReplicaSetAvailable" equals "$(progress_reason)" "NewReplicaSetAvailable"
check "Pods no longer use the broken 1.27.99 image" image_not_broken
check "Deployment was recovered, not deleted and recreated" deployment_not_recreated

finish
