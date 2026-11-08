#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-03
R='{.spec.template.spec.containers[0].resources'

check "Deployment report-generator rolls out and is Available" rollout_ok "$NS" report-generator
check "2 replicas are ready" equals "$(jp "$NS" deploy/report-generator '{.status.readyReplicas}')" "2"
check "CPU request is still set"    not_empty "$(jp "$NS" deploy/report-generator "$R.requests.cpu}")"
check "Memory request is still set" not_empty "$(jp "$NS" deploy/report-generator "$R.requests.memory}")"
check "CPU limit is still set"      not_empty "$(jp "$NS" deploy/report-generator "$R.limits.cpu}")"
check "Memory limit is still set"   not_empty "$(jp "$NS" deploy/report-generator "$R.limits.memory}")"

finish
