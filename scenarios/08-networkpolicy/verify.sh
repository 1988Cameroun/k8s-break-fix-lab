#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-08

can_reach() { kubectl -n "$NS" exec "deploy/$1" -- wget -qO- -T 3 http://api | grep -q 'Welcome to nginx'; }
deny_all_kept() {
  equals "$(jp "$NS" networkpolicy/default-deny-ingress '{.spec.podSelector}{.spec.policyTypes[*]}')" "{}Ingress"
}
labels_unchanged() {
  equals "$(jp "$NS" deploy/web '{.spec.template.metadata.labels.app}/{.spec.template.metadata.labels.tier}')" "web/frontend" &&
  equals "$(jp "$NS" deploy/intruder '{.spec.template.metadata.labels.app}')" "intruder"
}

for d in api web intruder; do
  check "Deployment $d is Available" rollout_ok "$NS" "$d"
done
check "default-deny-ingress policy is still in place" deny_all_kept
check "Pod labels are unchanged" labels_unchanged
check "web can reach http://api" can_reach web
check_not "intruder is blocked from http://api" can_reach intruder

if (( _FAILED )) && can_reach intruder 2>/dev/null && deny_all_kept 2>/dev/null; then
  warn "intruder can reach api even with default-deny in place. Your CNI may not enforce"
  warn "NetworkPolicy. Recreate the cluster with kind v0.25+ (./lab.sh down && ./lab.sh up)."
fi

finish
