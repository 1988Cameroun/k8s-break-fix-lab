#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-07

reaches_pricing() {
  # shellcheck disable=SC2016  # $PRICING_URL is expanded inside the pod
  kubectl -n "$NS" exec deploy/orders -- sh -c 'wget -qO- -T 3 "$PRICING_URL"' | grep -q 'Welcome to nginx'
}

check "pricing is Available in lab-07-data" rollout_ok lab-07-data pricing
check "orders rolls out and is Ready" rollout_ok "$NS" orders
check "No pricing Service was copied into lab-07" \
  bash -c "! kubectl -n $NS get svc pricing"
check "orders can fetch from pricing using \$PRICING_URL" reaches_pricing

finish
