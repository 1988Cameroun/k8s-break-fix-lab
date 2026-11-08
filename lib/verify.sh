# shellcheck shell=bash
# Helpers sourced by every scenarios/*/verify.sh.
#
# A verify script is a list of `check "<description>" <command...>` lines
# followed by `finish`. A check passes when its command exits 0.

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# How long to wait for things like rollouts before declaring failure.
VERIFY_TIMEOUT="${VERIFY_TIMEOUT:-60}"
_FAILED=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  %s✔%s %s\n' "$GREEN" "$RESET" "$desc"
  else
    printf '  %s✘%s %s\n' "$RED" "$RESET" "$desc"
    _FAILED=1
  fi
}

# check_not "<description>" <command...>  passes when the command FAILS.
check_not() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  %s✘%s %s\n' "$RED" "$RESET" "$desc"
    _FAILED=1
  else
    printf '  %s✔%s %s\n' "$GREEN" "$RESET" "$desc"
  fi
}

# rollout_ok <namespace> <deployment>
rollout_ok() {
  kubectl -n "$1" rollout status "deploy/$2" --timeout="${VERIFY_TIMEOUT}s"
}

# jp <namespace> <resource> <jsonpath>   -> prints the jsonpath result
jp() {
  kubectl -n "$1" get "$2" -o "jsonpath=$3"
}

# equals <actual> <expected>
equals() { [[ "$1" == "$2" ]]; }

# not_empty <value>
not_empty() { [[ -n "$1" ]]; }

# ready_endpoints <namespace> <service>  -> prints how many Ready endpoints the Service has
ready_endpoints() {
  kubectl -n "$1" get endpointslices -l "kubernetes.io/service-name=$2" \
    -o go-template='{{range .items}}{{range .endpoints}}{{if .conditions.ready}}x{{"\n"}}{{end}}{{end}}{{end}}' \
    | grep -c x
}

# no_restarts <namespace> <label-selector>
# Passes when every matching pod has zero container restarts.
no_restarts() {
  local counts
  # go-template so pods that are already terminating (old ReplicaSet) are skipped.
  counts="$(kubectl -n "$1" get pods -l "$2" -o go-template='{{range .items}}{{if not .metadata.deletionTimestamp}}{{range .status.containerStatuses}}{{.restartCount}}{{"\n"}}{{end}}{{end}}{{end}}')"
  [[ -n "$counts" ]] && ! grep -qv '^0$' <<<"$counts"
}

finish() {
  echo
  if (( _FAILED )); then
    printf '%sNot fixed yet.%s Keep digging, or run %s./lab.sh hint%s.\n' "$RED" "$RESET" "$BOLD" "$RESET"
    exit 1
  fi
  printf '%sAll checks passed.%s\n' "$GREEN" "$RESET"
  exit 0
}
