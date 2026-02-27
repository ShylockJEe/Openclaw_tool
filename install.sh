#!/usr/bin/env bash

# This installer relies on Bash features (arrays, BASH_SOURCE).
# If invoked via `sh`, provide a clear error and guidance.
if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    case "${0##*/}" in
      sh|dash|ash)
        echo "ERROR: This installer must run with bash, not sh."
        echo "Use:"
        echo "  curl -fsSL https://raw.githubusercontent.com/ShylockJEe/Openclaw_tool/main/bootstrap.sh | bash -s -- --fast"
        exit 1
        ;;
      *)
        exec bash "$0" "$@"
        ;;
    esac
  else
    echo "ERROR: bash is not installed. Please install bash first."
    exit 1
  fi
fi

set -uo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -z "$SCRIPT_SOURCE" ]]; then
  echo "ERROR: install.sh cannot run from stdin because it requires bundled library files."
  echo "Use:"
  echo "  curl -fsSL https://raw.githubusercontent.com/ShylockJEe/Openclaw_tool/main/bootstrap.sh | bash -s -- --fast"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"

# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/diagnose.sh
source "$SCRIPT_DIR/scripts/lib/diagnose.sh"
# shellcheck source=scripts/lib/preflight.sh
source "$SCRIPT_DIR/scripts/lib/preflight.sh"

print_banner() {
  cat <<'EOF'
====================================
 OpenClaw Smart Installer (Wrapper)
====================================
EOF
}

print_quick_summary() {
  log_info "Quick summary:"
  log_info "  os=${DETECTED_OS:-unknown} arch=${DETECTED_ARCH:-unknown} pkg=${PKG_MANAGER:-none}"
  log_info "  mode=$([[ "$OPENCLAW_FAST_MODE" == "true" ]] && echo fast || echo standard) dry_run=$OPENCLAW_DRY_RUN"
}

dependency_plan() {
  local items=()

  items+=("git")

  if [[ "$OPENCLAW_SKIP_NODE" != "true" ]]; then
    items+=("node")
  fi

  if [[ "$OPENCLAW_SKIP_PNPM" != "true" ]]; then
    items+=("pnpm")
  fi

  if [[ "$OPENCLAW_SKIP_DOCKER" != "true" ]]; then
    items+=("docker")
  fi

  printf "%s" "${items[*]}"
}

preview_plan() {
  if [[ "$OPENCLAW_SKIP_NODE" == "true" ]]; then
    log_info "Skip Node.js check/install by user option."
  fi
  if [[ "$OPENCLAW_SKIP_PNPM" == "true" ]]; then
    log_info "Skip pnpm check/install by user option."
  fi
  if [[ "$OPENCLAW_SKIP_DOCKER" == "true" ]]; then
    log_info "Skip Docker check/install by user option."
  fi

  local planned=()
  local plan_text=""
  plan_text="$(dependency_plan)"
  read -r -a planned <<<"$plan_text"

  if [[ ${#planned[@]} -eq 0 ]]; then
    log_warn "Dependency plan: nothing to install."
    return 0
  fi

  log_info "Dependency plan: ${planned[*]}"
}

install_missing_dependencies() {
  local dep
  local planned=()
  local plan_text=""
  plan_text="$(dependency_plan)"
  read -r -a planned <<<"$plan_text"

  if [[ ${#planned[@]} -eq 0 ]]; then
    log_warn "No dependency checks enabled."
    return 0
  fi

  if [[ -z "${PKG_MANAGER:-}" ]]; then
    for dep in "${planned[@]}"; do
      if ! dependency_installed "$dep"; then
        return "$ERR_NO_PACKAGE_MANAGER"
      fi
    done
    return 0
  fi

  for dep in "${planned[@]}"; do
    if dependency_installed "$dep"; then
      log_success "Dependency '$dep' already installed."
      continue
    fi

    log_info "Dependency '$dep' is missing, installing..."
    if ! install_dependency "$dep"; then
      case "$dep" in
        node) return "$ERR_NODE_INSTALL" ;;
        pnpm) return "$ERR_PNPM_INSTALL" ;;
        docker) return "$ERR_DOCKER_INSTALL" ;;
        *) return "$ERR_UNKNOWN" ;;
      esac
    fi
  done

  return 0
}

run_official_installer() {
  if [[ "${OPENCLAW_SKIP_OFFICIAL:-false}" == "true" ]]; then
    log_warn "OPENCLAW_SKIP_OFFICIAL=true, skip official installer."
    return 0
  fi

  local tmp_file=""
  if [[ "$OPENCLAW_DRY_RUN" != "true" ]] && [[ "${OPENCLAW_TEST_MODE:-false}" != "true" ]]; then
    tmp_file="$(mktemp /tmp/openclaw-official-XXXXXX.sh)"
  else
    tmp_file="/tmp/openclaw-official-preview.sh"
  fi

  log_info "Fetching official installer from: $OPENCLAW_OFFICIAL_SH_URL"
  if command_exists curl; then
    if ! run_cmd curl -fsSL "$OPENCLAW_OFFICIAL_SH_URL" -o "$tmp_file"; then
      return "$ERR_OFFICIAL_INSTALLER"
    fi
  elif command_exists wget; then
    if ! run_cmd wget -q "$OPENCLAW_OFFICIAL_SH_URL" -O "$tmp_file"; then
      return "$ERR_OFFICIAL_INSTALLER"
    fi
  else
    log_error "curl/wget not found, cannot download official installer."
    return "$ERR_OFFICIAL_INSTALLER"
  fi

  run_cmd chmod +x "$tmp_file" || return "$ERR_OFFICIAL_INSTALLER"
  log_info "Running official installer..."
  if ! run_cmd bash "$tmp_file"; then
    return "$ERR_OFFICIAL_INSTALLER"
  fi

  if [[ "$OPENCLAW_DRY_RUN" != "true" ]] && [[ "${OPENCLAW_TEST_MODE:-false}" != "true" ]]; then
    rm -f "$tmp_file"
  fi
  return 0
}

verify_installation() {
  local failed=0

  if ! dependency_installed git; then
    log_error "Verification failed: git not found."
    failed=1
  fi

  if [[ "$OPENCLAW_SKIP_NODE" != "true" ]] && ! dependency_installed node; then
    log_error "Verification failed: node not found."
    failed=1
  fi

  if [[ "$OPENCLAW_SKIP_PNPM" != "true" ]] && ! dependency_installed pnpm; then
    log_error "Verification failed: pnpm not found."
    failed=1
  fi

  if [[ "$OPENCLAW_SKIP_DOCKER" != "true" ]] && ! dependency_installed docker; then
    log_error "Verification failed: docker not found."
    failed=1
  fi

  if [[ "$failed" -ne 0 ]]; then
    return "$ERR_VERIFY"
  fi

  log_success "Verification passed."
  return 0
}

print_next_steps() {
  cat <<'EOF'
Next steps:
1. Read quick start: https://docs.openclaw.ai/start/getting-started
2. Enter your OpenClaw workspace and start the service as documented.
3. If startup fails, rerun installer with --verbose and share openclaw-install.log.
EOF
}

main() {
  init_logging
  print_banner

  parse_args "$@"
  case "$?" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac

  if ! run_preflight; then
    local code="$?"
    log_error "Preflight failed with code=$code"
    print_fix_suggestion "$code"
    return "$code"
  fi

  print_quick_summary
  preview_plan

  if [[ "$OPENCLAW_DRY_RUN" == "true" ]]; then
    log_success "Dry-run completed."
    return 0
  fi

  if ! install_missing_dependencies; then
    local code="$?"
    log_error "Dependency installation failed with code=$code"
    print_fix_suggestion "$code"
    return "$code"
  fi

  if ! run_official_installer; then
    local code="$?"
    log_error "Official installer failed with code=$code"
    print_fix_suggestion "$code"
    return "$code"
  fi

  if ! verify_installation; then
    local code="$?"
    log_error "Verification failed with code=$code"
    print_fix_suggestion "$code"
    return "$code"
  fi

  log_success "OpenClaw installation completed."
  print_next_steps
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
