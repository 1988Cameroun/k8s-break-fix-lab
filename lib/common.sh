# shellcheck shell=bash
# Shared helpers for lab.sh and the scenario verify scripts.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'
  YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi
export BOLD DIM RED GREEN YELLOW BLUE RESET

info() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
ok()   { printf '%s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s!!%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%sxx%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

require() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "'$c' is required but was not found on your PATH."
  done
}
