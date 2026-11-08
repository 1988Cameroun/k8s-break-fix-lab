#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-10
SA="system:serviceaccount:lab-10:pod-watcher"

can() { [[ "$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null)" == "yes" ]]; }

check "pod-watcher rolls out and is Ready" rollout_ok "$NS" pod-watcher
check "Deployment still uses the pod-watcher ServiceAccount" \
  equals "$(jp "$NS" deploy/pod-watcher '{.spec.template.spec.serviceAccountName}')" "pod-watcher"
check "ServiceAccount can list pods in lab-10" can list pods -n "$NS"
check_not "ServiceAccount cannot delete pods" can delete pods -n "$NS"
check_not "ServiceAccount cannot read secrets" can get secrets -n "$NS"
check_not "ServiceAccount cannot list pods in other namespaces" can list pods -n kube-system
check_not "ServiceAccount cannot list pods cluster-wide" can list pods --all-namespaces

finish
