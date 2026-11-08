#!/usr/bin/env bash
# k8s-break-fix-lab: break a Kubernetes cluster on purpose, then fix it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-k8s-lab}"
SCENARIOS_DIR="$ROOT/scenarios"
STATE_DIR="$ROOT/.lab-state"

# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

usage() {
  cat <<EOF
${BOLD}k8s-break-fix-lab${RESET} — practice Kubernetes troubleshooting on a local kind cluster.

${BOLD}Cluster${RESET}
  ./lab.sh up                  Create the local kind cluster ($CLUSTER_NAME)
  ./lab.sh down                Delete the cluster

${BOLD}Scenarios${RESET}
  ./lab.sh list                List scenarios and your progress
  ./lab.sh start <id>          Break things: deploy scenario <id> (e.g. 01 or 1)
  ./lab.sh hint [id] [n]       Show the next hint (or hint n)
  ./lab.sh check [id]          Verify your fix
  ./lab.sh solution [id]       Show the full write-up (spoilers!)
  ./lab.sh reset [id]          Remove the scenario's namespaces

[id] defaults to the scenario you started most recently.
EOF
}

# --- helpers -----------------------------------------------------------------

state_get() { [[ -f "$STATE_DIR/$1" ]] && cat "$STATE_DIR/$1" || true; }
state_set() { mkdir -p "$STATE_DIR"; printf '%s\n' "$2" >"$STATE_DIR/$1"; }

# Resolve "1", "01" or "01-crashloop" to a scenario directory.
resolve() {
  local id="${1:-$(state_get current)}"
  [[ -n "$id" ]] || die "No scenario given and none started yet. Try: ./lab.sh list"
  [[ "$id" =~ ^[0-9]$ ]] && id="0$id"
  local dir
  for dir in "$SCENARIOS_DIR"/"$id"*/; do
    [[ -d "$dir" ]] && { echo "${dir%/}"; return; }
  done
  die "No scenario matches '$id'. Run: ./lab.sh list"
}

load_conf() {
  TITLE=""; DIFFICULTY=""; NAMESPACES=""
  # shellcheck source=/dev/null
  source "$1/scenario.conf"
}

# Refuse to touch anything other than the lab cluster, so a stray
# `./lab.sh start` can never delete namespaces on a real cluster.
require_lab_context() {
  require kubectl
  local ctx
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$ctx" != "kind-$CLUSTER_NAME" && -z "${LAB_ALLOW_ANY_CONTEXT:-}" ]]; then
    die "Current kubectl context is '${ctx:-<none>}', not 'kind-$CLUSTER_NAME'.
   Run ./lab.sh up, or: kubectl config use-context kind-$CLUSTER_NAME
   (Set LAB_ALLOW_ANY_CONTEXT=1 to override — only on a throwaway cluster.)"
  fi
  kubectl get --raw /readyz >/dev/null 2>&1 || die "Cluster is not reachable. Is Docker running? Try ./lab.sh up"
}

delete_namespaces() {
  local ns
  for ns in $NAMESPACES; do
    kubectl delete namespace "$ns" --ignore-not-found --wait=true --timeout=180s >/dev/null
  done
}

# --- commands ----------------------------------------------------------------

cmd_up() {
  require docker kind kubectl
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    info "Cluster '$CLUSTER_NAME' already exists."
  else
    info "Creating kind cluster '$CLUSTER_NAME' (1 control plane, 2 workers)..."
    kind create cluster --name "$CLUSTER_NAME" --config "$ROOT/kind/cluster.yaml" --wait 180s
  fi
  kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
  kubectl get nodes
  echo
  ok "Ready. Next: ./lab.sh list"
}

cmd_down() {
  require kind
  kind delete cluster --name "$CLUSTER_NAME"
  rm -f "$STATE_DIR/current"
}

cmd_list() {
  printf '%s%-4s %-52s %-8s %s%s\n' "$BOLD" "ID" "SCENARIO" "LEVEL" "STATUS" "$RESET"
  local dir id solved
  for dir in "$SCENARIOS_DIR"/*/; do
    dir="${dir%/}"; id="$(basename "$dir" | cut -d- -f1)"
    load_conf "$dir"
    solved="$(state_get "solved-$id")"
    printf '%-4s %-52s %-8s %s\n' "$id" "$TITLE" "$DIFFICULTY" \
      "${solved:+${GREEN}solved $solved${RESET}}"
  done
}

cmd_start() {
  local dir id
  dir="$(resolve "${1:-}")"; id="$(basename "$dir" | cut -d- -f1)"
  require_lab_context
  load_conf "$dir"

  info "Resetting namespaces: $NAMESPACES"
  delete_namespaces
  info "Deploying scenario $id: $TITLE"
  kubectl apply -f "$dir/manifests.yaml" >/dev/null
  if [[ -x "$dir/setup.sh" ]]; then
    "$dir/setup.sh"
  fi

  state_set current "$id"
  rm -f "$STATE_DIR/hints-$id"
  echo
  cat "$dir/README.md"
  echo
  printf '%sWhen you think it is fixed:%s ./lab.sh check    %sStuck?%s ./lab.sh hint\n' \
    "$BOLD" "$RESET" "$BOLD" "$RESET"
}

cmd_hint() {
  local dir id total n
  dir="$(resolve "${1:-}")"; id="$(basename "$dir" | cut -d- -f1)"
  total="$(grep -c '^## Hint ' "$dir/hints.md")"
  if [[ -n "${2:-}" ]]; then
    n="$2"
  else
    n=$(( $(state_get "hints-$id" || echo 0) + 1 ))
    (( n > total )) && n="$total"
    state_set "hints-$id" "$n"
  fi
  (( n >= 1 && n <= total )) || die "Scenario $id has hints 1-$total."
  awk -v n="$n" '/^## Hint /{c++} c==n' "$dir/hints.md"
  echo
  (( n < total )) && printf '%s(hint %d of %d — run again for the next one)%s\n' "$DIM" "$n" "$total" "$RESET"
  return 0
}

cmd_check() {
  local dir id
  dir="$(resolve "${1:-}")"; id="$(basename "$dir" | cut -d- -f1)"
  require_lab_context
  load_conf "$dir"
  info "Checking scenario $id: $TITLE"
  if "$dir/verify.sh"; then
    state_set "solved-$id" "$(date +%Y-%m-%d)"
    echo
    ok "Scenario $id solved. Read the write-up: ./lab.sh solution $id"
  else
    return 1
  fi
}

cmd_solution() {
  local dir answer
  dir="$(resolve "${1:-}")"
  if [[ -t 0 && -z "${LAB_YES:-}" ]]; then
    read -r -p "Show the full solution? Try the hints first. [y/N] " answer
    [[ "$answer" =~ ^[Yy] ]] || exit 0
  fi
  cat "$dir/SOLUTION.md"
}

cmd_reset() {
  local dir
  dir="$(resolve "${1:-}")"
  require_lab_context
  load_conf "$dir"
  info "Deleting namespaces: $NAMESPACES"
  delete_namespaces
  ok "Reset."
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    up)        cmd_up ;;
    down)      cmd_down ;;
    list|ls)   cmd_list ;;
    start)     cmd_start "$@" ;;
    hint)      cmd_hint "$@" ;;
    check)     cmd_check "$@" ;;
    solution)  cmd_solution "$@" ;;
    reset)     cmd_reset "$@" ;;
    help|-h|--help) usage ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
