#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-04

has_endpoints() { (( $(ready_endpoints "$NS" checkout) > 0 )); }
request_works() {
  kubectl -n "$NS" exec deploy/toolbox -- wget -qO- -T 3 http://checkout | grep -q 'Welcome to nginx'
}

check "checkout Deployment is Available" rollout_ok "$NS" checkout
check "toolbox Deployment is Available" rollout_ok "$NS" toolbox
check "checkout Deployment selector unchanged (app=checkout, tier=api)" \
  equals "$(jp "$NS" deploy/checkout '{.spec.selector.matchLabels.app}/{.spec.selector.matchLabels.tier}')" "checkout/api"
check "Service checkout has endpoints" has_endpoints
check "http://checkout returns the nginx welcome page" request_works

finish
