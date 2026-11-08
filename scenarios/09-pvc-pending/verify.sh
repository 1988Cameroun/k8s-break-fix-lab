#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-09

class_exists() {
  local sc
  sc="$(jp "$NS" pvc/uploads '{.spec.storageClassName}')"
  [[ -n "$sc" ]] && kubectl get storageclass "$sc"
}
at_least_1gi() {
  local size
  size="$(jp "$NS" pvc/uploads '{.spec.resources.requests.storage}')"
  # Accept 1Gi or more, written in Gi or Mi.
  if [[ "$size" =~ ^([0-9]+)Gi$ ]]; then (( BASH_REMATCH[1] >= 1 )); return; fi
  if [[ "$size" =~ ^([0-9]+)Mi$ ]]; then (( BASH_REMATCH[1] >= 1024 )); return; fi
  return 1
}

check "Deployment uploader rolls out and is Available" rollout_ok "$NS" uploader
check "PVC uploads is Bound" equals "$(jp "$NS" pvc/uploads '{.status.phase}')" "Bound"
check "PVC uses a StorageClass that exists" class_exists
check "PVC requests at least 1Gi" at_least_1gi
check "uploader mounts the uploads claim" \
  equals "$(jp "$NS" deploy/uploader '{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')" "uploads"

finish
