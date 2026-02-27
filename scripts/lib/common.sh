#!/usr/bin/env bash

set -u

OPENCLAW_DRY_RUN="${OPENCLAW_DRY_RUN:-false}"
OPENCLAW_ALLOW_SUDO="${OPENCLAW_ALLOW_SUDO:-true}"
OPENCLAW_SKIP_NODE="${OPENCLAW_SKIP_NODE:-false}"
OPENCLAW_SKIP_PNPM="${OPENCLAW_SKIP_PNPM:-false}"
OPENCLAW_SKIP_DOCKER="${OPENCLAW_SKIP_DOCKER:-false}"
OPENCLAW_VERBOSE="${OPENCLAW_VERBOSE:-false}"
OPENCLAW_FAST_MODE="${OPENCLAW_FAST_MODE:-false}"
OPENCLAW_OFFICIAL_SH_URL="${OPENCLAW_OFFICIAL_SH_URL:-https://www.openclaw.ai/install.sh}"
OPENCLAW_OFFICIAL_PS1_URL="${OPENCLAW_OFFICIAL_PS1_URL:-https://www.openclaw.ai/install.ps1}"
OPENCLAW_LOG_FILE="${OPENCLAW_LOG_FILE:-./openclaw-install.log}"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

init_logging() {
  if ! ( : >>"$OPENCLAW_LOG_FILE" ) 2>/dev/null; then
    OPENCLAW_LOG_FILE="/tmp/openclaw-install.log"
    : >>"$OPENCLAW_LOG_FILE"
  fi
}

_log() {
  local level="$1"
  shift
  local line
  line="[$(timestamp)] [$level] $*"
  printf "%s\n" "$line"
  printf "%s\n" "$line" >>"$OPENCLAW_LOG_FILE"
}

log_info() {
  _log INFO "$*"
}

log_warn() {
  _log WARN "$*"
}

log_error() {
  _log ERROR "$*"
}

log_success() {
  _log OK "$*"
}

debug() {
  if [[ "$OPENCLAW_VERBOSE" == "true" ]]; then
    _log DEBUG "$*"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_true() {
  case "${1:-}" in
    true|TRUE|True|1|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

run_cmd() {
  if [[ "${OPENCLAW_TEST_MODE:-false}" == "true" ]]; then
    log_info "[test-mode] $*"
    return 0
  fi

  if [[ "$OPENCLAW_DRY_RUN" == "true" ]]; then
    log_info "[dry-run] $*"
    return 0
  fi

  debug "run: $*"
  "$@"
}

run_with_optional_sudo() {
  if [[ "$OPENCLAW_ALLOW_SUDO" == "true" ]] && [[ "$(id -u)" -ne 0 ]] && command_exists sudo; then
    run_cmd sudo "$@"
    return $?
  fi

  run_cmd "$@"
}

die() {
  log_error "$*"
  return 1
}

print_usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --fast              Fast mode (quick summary + auto-continue)
  --dry-run           Run checks only, do not install
  --allow-sudo        Allow sudo elevation (default)
  --no-sudo           Disable sudo usage
  --skip-node         Skip Node.js installation/check
  --skip-pnpm         Skip pnpm installation/check
  --skip-docker       Skip Docker installation/check
  --official-url URL  Override official install.sh URL
  --verbose           Enable verbose logs
  --help              Show this help message
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        OPENCLAW_DRY_RUN="true"
        ;;
      --fast)
        OPENCLAW_FAST_MODE="true"
        OPENCLAW_VERBOSE="true"
        ;;
      --allow-sudo)
        OPENCLAW_ALLOW_SUDO="true"
        ;;
      --no-sudo)
        OPENCLAW_ALLOW_SUDO="false"
        ;;
      --skip-node)
        OPENCLAW_SKIP_NODE="true"
        ;;
      --skip-pnpm)
        OPENCLAW_SKIP_PNPM="true"
        ;;
      --skip-docker)
        OPENCLAW_SKIP_DOCKER="true"
        ;;
      --official-url)
        shift
        if [[ $# -eq 0 ]]; then
          die "Missing value after --official-url" || true
          return 1
        fi
        OPENCLAW_OFFICIAL_SH_URL="$1"
        ;;
      --verbose)
        OPENCLAW_VERBOSE="true"
        ;;
      --help|-h)
        print_usage
        return 2
        ;;
      *)
        die "Unknown argument: $1" || true
        print_usage
        return 1
        ;;
    esac
    shift
  done

  return 0
}
