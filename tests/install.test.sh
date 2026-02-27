#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf "FAIL: %s\n" "$*" >&2
  exit 1
}

assert_contains() {
  local text="$1"
  local expected="$2"
  if [[ "$text" != *"$expected"* ]]; then
    fail "expected output to contain: $expected"
  fi
}

run_case() {
  local name="$1"
  shift
  printf "Running: %s\n" "$name"
  "$@"
}

case_help() {
  local out
  out="$("$ROOT_DIR/install.sh" --help 2>&1 || true)"
  assert_contains "$out" "Usage:"
  assert_contains "$out" "--dry-run"
}

case_dry_run_success() {
  local out
  out="$(OPENCLAW_TEST_MODE=true OPENCLAW_SKIP_OFFICIAL=true "$ROOT_DIR/install.sh" --dry-run 2>&1)"
  assert_contains "$out" "Dry-run completed."
}

case_fast_mode() {
  local out
  out="$(OPENCLAW_TEST_MODE=true OPENCLAW_SKIP_OFFICIAL=true "$ROOT_DIR/install.sh" --fast --dry-run 2>&1)"
  assert_contains "$out" "mode=fast"
  assert_contains "$out" "Dry-run completed."
}

case_skip_flags() {
  local out
  out="$(OPENCLAW_TEST_MODE=true OPENCLAW_SKIP_OFFICIAL=true "$ROOT_DIR/install.sh" --dry-run --skip-docker --skip-node --skip-pnpm 2>&1)"
  assert_contains "$out" "Skip Docker check/install by user option."
  assert_contains "$out" "Skip Node.js check/install by user option."
  assert_contains "$out" "Skip pnpm check/install by user option."
}

case_invalid_argument() {
  local out=""
  local status=0
  set +e
  out="$("$ROOT_DIR/install.sh" --not-exists 2>&1)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    fail "expected invalid argument to fail"
  fi
  assert_contains "$out" "Unknown argument"
}

case_dns_failure_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 1; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=24"
}

case_tls_failure_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 1; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=25"
}

case_source_failure_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 1; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=26"
}

case_permission_failure_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    detect_os() { DETECTED_OS="linux"; }
    detect_arch() { DETECTED_ARCH="amd64"; }
    detect_package_manager() { PKG_MANAGER="apt-get"; return 0; }
    require_install_permission() { return 1; }
    run_full_diagnostics() { return 0; }
    run_preflight
    echo "code=$?"
  ')"
  assert_contains "$out" "code=23"
}

case_git_missing_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 1; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=27"
}

case_node_version_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 1; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=28"
}

case_pnpm_version_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 1; }
    check_docker_daemon() { return 0; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=29"
}

case_docker_daemon_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    check_dns_resolution() { return 0; }
    check_https_connectivity() { return 0; }
    check_source_reachability() { return 0; }
    check_proxy_env() { return 0; }
    check_disk_memory() { return 0; }
    check_common_ports() { return 0; }
    check_git_installed() { return 0; }
    check_node_version() { return 0; }
    check_pnpm_version() { return 0; }
    check_docker_daemon() { return 1; }
    run_full_diagnostics
    echo "code=$?"
  ')"
  assert_contains "$out" "code=31"
}

case_no_package_manager_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/install.sh"
    PKG_MANAGER=""
    OPENCLAW_SKIP_NODE=false
    OPENCLAW_SKIP_PNPM=false
    OPENCLAW_SKIP_DOCKER=false
    dependency_installed() { return 1; }
    install_missing_dependencies
    echo "code=$?"
  ')"
  assert_contains "$out" "code=22"
}

case_official_installer_failure_mapping() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/install.sh"
    OPENCLAW_SKIP_OFFICIAL=false
    OPENCLAW_DRY_RUN=true
    command_exists() { return 1; }
    run_official_installer
    echo "code=$?"
  ')"
  assert_contains "$out" "code=50"
}

case_wsl_detection() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    uname() { echo "Linux"; }
    grep() { return 0; }
    detect_os
    echo "os=$DETECTED_OS"
  ')"
  assert_contains "$out" "os=wsl"
}

case_main_dependency_error_code() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/install.sh"
    init_logging() { :; }
    print_banner() { :; }
    parse_args() { return 0; }
    run_preflight() { return 0; }
    print_quick_summary() { :; }
    preview_plan() { :; }
    install_missing_dependencies() { return 41; }
    run_official_installer() { return 0; }
    verify_installation() { return 0; }
    print_fix_suggestion() { echo "fix:$1"; }
    OPENCLAW_DRY_RUN=false
    main
    echo "code=$?"
  ')"
  assert_contains "$out" "Dependency installation failed with code=41"
  assert_contains "$out" "code=41"
}

case_pnpm_insecure_retry_path() {
  local out
  out="$(bash -c '
    set -u
    source "'"$ROOT_DIR"'/scripts/lib/common.sh"
    source "'"$ROOT_DIR"'/scripts/lib/diagnose.sh"
    source "'"$ROOT_DIR"'/scripts/lib/preflight.sh"
    PKG_MANAGER="brew"
    install_pnpm_with_package_manager() { return 1; }
    command_exists() { [[ "$1" == "npm" ]]; }
    calls=0
    run_with_optional_sudo() {
      calls=$((calls + 1))
      if [[ $calls -eq 1 ]]; then
        return 1
      fi
      return 0
    }
    install_pnpm
    echo "rc=$? calls=$calls"
  ')"
  assert_contains "$out" "rc=0"
  assert_contains "$out" "calls=2"
}

main() {
  run_case "help" case_help
  run_case "dry-run" case_dry_run_success
  run_case "fast-mode" case_fast_mode
  run_case "skip-flags" case_skip_flags
  run_case "invalid-argument" case_invalid_argument
  run_case "dns-failure" case_dns_failure_mapping
  run_case "tls-failure" case_tls_failure_mapping
  run_case "source-failure" case_source_failure_mapping
  run_case "permission-failure" case_permission_failure_mapping
  run_case "git-missing" case_git_missing_mapping
  run_case "node-version" case_node_version_mapping
  run_case "pnpm-version" case_pnpm_version_mapping
  run_case "docker-daemon" case_docker_daemon_mapping
  run_case "no-pkg-manager" case_no_package_manager_mapping
  run_case "official-installer-failure" case_official_installer_failure_mapping
  run_case "wsl-detection" case_wsl_detection
  run_case "main-error-code" case_main_dependency_error_code
  run_case "pnpm-insecure-retry" case_pnpm_insecure_retry_path
  printf "PASS: install.test.sh\n"
}

main "$@"
