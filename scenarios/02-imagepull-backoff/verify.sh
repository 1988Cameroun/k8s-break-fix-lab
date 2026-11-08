#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=lib/verify.sh
source "$(dirname "$0")/../../lib/verify.sh"
NS=lab-02

is_nginx_127_alpine() {
  local image re='^(docker\.io/(library/)?)?nginx:1\.27(\.[0-9]+)?-alpine'
  image="$(jp "$NS" deploy/storefront '{.spec.template.spec.containers[0].image}')"
  [[ "$image" =~ $re ]]
}

check "Deployment storefront rolls out and is Available" rollout_ok "$NS" storefront
check "Image is an nginx 1.27 Alpine tag" is_nginx_127_alpine
check "2 replicas are ready" \
  equals "$(jp "$NS" deploy/storefront '{.status.readyReplicas}')" "2"

finish
