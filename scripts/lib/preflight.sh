#!/usr/bin/env bash

DETECTED_OS=""
DETECTED_ARCH=""
PKG_MANAGER=""

version_major() {
  local raw="${1:-}"
  raw="${raw#v}"
  raw="${raw%%[^0-9.]*}"
  printf "%s" "${raw%%.*}"
}

detect_os() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"

  case "$uname_s" in
    Darwin)
      DETECTED_OS="macos"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        DETECTED_OS="wsl"
      else
        DETECTED_OS="linux"
      fi
      ;;
    *)
      DETECTED_OS="unsupported"
      ;;
  esac
}

detect_arch() {
  local uname_m
  uname_m="$(uname -m 2>/dev/null || echo unknown)"
  case "$uname_m" in
    x86_64|amd64) DETECTED_ARCH="amd64" ;;
    arm64|aarch64) DETECTED_ARCH="arm64" ;;
    *) DETECTED_ARCH="$uname_m" ;;
  esac
}

detect_package_manager() {
  local pm
  for pm in brew apt-get dnf yum pacman apk zypper; do
    if command_exists "$pm"; then
      PKG_MANAGER="$pm"
      return 0
    fi
  done

  PKG_MANAGER=""
  return 1
}

check_dns_resolution() {
  local host="${1:-www.openclaw.ai}"

  if command_exists getent; then
    getent hosts "$host" >/dev/null 2>&1
    return $?
  fi

  if command_exists nslookup; then
    nslookup "$host" >/dev/null 2>&1
    return $?
  fi

  if command_exists dig; then
    dig +short "$host" 2>/dev/null | grep -q .
    return $?
  fi

  if command_exists ping; then
    ping -c 1 -W 2 "$host" >/dev/null 2>&1
    return $?
  fi

  log_warn "No DNS probe tool found (getent/nslookup/dig/ping), skip DNS check."
  return 0
}

check_https_connectivity() {
  local target="${1:-https://www.openclaw.ai}"

  if command_exists curl; then
    curl -I -fsSL --max-time 10 "$target" >/dev/null 2>&1
    return $?
  fi

  if command_exists wget; then
    wget -q --spider --timeout=10 "$target" >/dev/null 2>&1
    return $?
  fi

  log_warn "Neither curl nor wget found, skip HTTPS connectivity check."
  return 0
}

check_source_reachability() {
  local target="${1:-$OPENCLAW_OFFICIAL_SH_URL}"

  if command_exists curl; then
    if curl -I -fsSL --max-time 10 "$target" >/dev/null 2>&1; then
      return 0
    fi
    curl -fsSL --max-time 10 "$target" -o /dev/null >/dev/null 2>&1
    return $?
  fi

  if command_exists wget; then
    wget -q --spider --timeout=10 "$target" >/dev/null 2>&1
    return $?
  fi

  log_warn "Neither curl nor wget found, skip source reachability check."
  return 0
}

check_proxy_env() {
  if [[ -n "${HTTP_PROXY:-}" ]] || [[ -n "${HTTPS_PROXY:-}" ]] || [[ -n "${http_proxy:-}" ]] || [[ -n "${https_proxy:-}" ]]; then
    log_info "Proxy environment detected."
  else
    log_info "Proxy environment not set."
  fi
  return 0
}

check_disk_memory() {
  local min_disk_gb min_mem_gb
  local disk_kb disk_gb
  local mem_mb mem_gb mem_bytes mem_kb

  min_disk_gb="${OPENCLAW_MIN_DISK_GB:-5}"
  min_mem_gb="${OPENCLAW_MIN_MEM_GB:-4}"
  disk_kb=""
  disk_gb=0
  mem_mb=""
  mem_gb=0

  if command_exists df; then
    disk_kb="$(df -Pk . 2>/dev/null | awk 'NR==2{print $4}')"
  fi

  if [[ -n "$disk_kb" ]] && [[ "$disk_kb" =~ ^[0-9]+$ ]]; then
    disk_gb=$((disk_kb / 1024 / 1024))
    if (( disk_gb < min_disk_gb )); then
      log_error "Disk available ${disk_gb}GB is below required ${min_disk_gb}GB."
      return 1
    fi
    log_success "Disk check passed (${disk_gb}GB available)."
  else
    log_warn "Unable to determine available disk size, skip strict disk check."
  fi

  if command_exists free; then
    mem_mb="$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')"
  elif command_exists sysctl; then
    mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo "")"
    if [[ -n "$mem_bytes" ]] && [[ "$mem_bytes" =~ ^[0-9]+$ ]]; then
      mem_mb=$((mem_bytes / 1024 / 1024))
    fi
  elif [[ -r /proc/meminfo ]]; then
    mem_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "")"
    if [[ -n "$mem_kb" ]] && [[ "$mem_kb" =~ ^[0-9]+$ ]]; then
      mem_mb=$((mem_kb / 1024))
    fi
  fi

  if [[ -n "$mem_mb" ]] && [[ "$mem_mb" =~ ^[0-9]+$ ]]; then
    mem_gb=$(((mem_mb + 1023) / 1024))
    if (( mem_gb < min_mem_gb )); then
      log_error "Memory ${mem_gb}GB is below required ${min_mem_gb}GB."
      return 1
    fi
    log_success "Memory check passed (${mem_gb}GB total)."
  else
    log_warn "Unable to determine memory size, skip strict memory check."
  fi

  return 0
}

check_common_ports() {
  local ports port
  local occupied=""

  ports="${OPENCLAW_PORT_CHECK_LIST:-3000 5173 5432 6379}"

  for port in $ports; do
    if command_exists lsof; then
      if lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
        occupied="${occupied} ${port}"
      fi
      continue
    fi

    if command_exists ss; then
      if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[\.:]${port}$"; then
        occupied="${occupied} ${port}"
      fi
      continue
    fi

    if command_exists netstat; then
      if netstat -an 2>/dev/null | grep -E "LISTEN|LISTENING" | grep -Eq "[\.:]${port}[[:space:]]"; then
        occupied="${occupied} ${port}"
      fi
    fi
  done

  if [[ -n "${occupied// }" ]]; then
    log_warn "Common ports already in use:${occupied}"
  else
    log_success "Common ports check passed."
  fi

  return 0
}

require_install_permission() {
  if [[ "$OPENCLAW_ALLOW_SUDO" != "true" ]]; then
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi

  if command_exists sudo; then
    return 0
  fi

  return 1
}

check_git_installed() {
  if command_exists git; then
    log_success "Git detected."
    return 0
  fi

  log_error "Git is required but not installed."
  return 1
}

check_node_version() {
  local current major min_major

  min_major=18
  if ! command_exists node; then
    log_warn "Node.js not installed yet, will attempt auto-install."
    return 0
  fi

  current="$(node -v 2>/dev/null || true)"
  major="$(version_major "$current")"
  if [[ -z "$major" ]] || ! [[ "$major" =~ ^[0-9]+$ ]]; then
    log_warn "Unable to parse Node.js version: ${current:-unknown}."
    return 0
  fi

  if (( major < min_major )); then
    log_error "Node.js version $current is below required v${min_major}."
    return 1
  fi

  log_success "Node.js version check passed ($current)."
  return 0
}

check_pnpm_version() {
  local current major min_major

  min_major=8
  if ! command_exists pnpm; then
    log_warn "pnpm not installed yet, will attempt auto-install."
    return 0
  fi

  current="$(pnpm -v 2>/dev/null || true)"
  major="$(version_major "$current")"
  if [[ -z "$major" ]] || ! [[ "$major" =~ ^[0-9]+$ ]]; then
    log_warn "Unable to parse pnpm version: ${current:-unknown}."
    return 0
  fi

  if (( major < min_major )); then
    log_error "pnpm version $current is below required ${min_major}."
    return 1
  fi

  log_success "pnpm version check passed ($current)."
  return 0
}

check_docker_daemon() {
  if [[ "$OPENCLAW_SKIP_DOCKER" == "true" ]]; then
    log_info "Skip Docker daemon check by user option."
    return 0
  fi

  if ! command_exists docker; then
    log_warn "Docker not installed yet, will attempt auto-install."
    return 0
  fi

  if docker info >/dev/null 2>&1; then
    log_success "Docker daemon check passed."
    return 0
  fi

  log_error "Docker command exists but daemon is not reachable."
  return 1
}

dependency_installed() {
  local dep="$1"
  case "$dep" in
    git) command_exists git ;;
    node) command_exists node ;;
    pnpm) command_exists pnpm ;;
    docker) command_exists docker ;;
    *)
      return 1
      ;;
  esac
}

install_git() {
  case "$PKG_MANAGER" in
    brew)
      run_cmd brew install git
      ;;
    apt-get)
      run_with_optional_sudo apt-get update
      run_with_optional_sudo apt-get install -y git
      ;;
    dnf)
      run_with_optional_sudo dnf install -y git
      ;;
    yum)
      run_with_optional_sudo yum install -y git
      ;;
    pacman)
      run_with_optional_sudo pacman -Sy --noconfirm git
      ;;
    apk)
      run_with_optional_sudo apk add git
      ;;
    zypper)
      run_with_optional_sudo zypper --non-interactive install git
      ;;
    *)
      return 1
      ;;
  esac
}

install_node() {
  case "$PKG_MANAGER" in
    brew)
      run_cmd brew install node
      ;;
    apt-get)
      run_with_optional_sudo apt-get update
      run_with_optional_sudo apt-get install -y nodejs npm
      ;;
    dnf)
      run_with_optional_sudo dnf install -y nodejs npm
      ;;
    yum)
      run_with_optional_sudo yum install -y nodejs npm
      ;;
    pacman)
      run_with_optional_sudo pacman -Sy --noconfirm nodejs npm
      ;;
    apk)
      run_with_optional_sudo apk add nodejs npm
      ;;
    zypper)
      run_with_optional_sudo zypper --non-interactive install nodejs20 npm20
      ;;
    *)
      return 1
      ;;
  esac
}

install_pnpm() {
  if command_exists npm; then
    run_with_optional_sudo npm install -g pnpm
    return $?
  fi

  case "$PKG_MANAGER" in
    brew)
      run_cmd brew install pnpm
      ;;
    apt-get)
      run_with_optional_sudo apt-get update
      run_with_optional_sudo apt-get install -y pnpm
      ;;
    dnf)
      run_with_optional_sudo dnf install -y pnpm
      ;;
    yum)
      run_with_optional_sudo yum install -y pnpm
      ;;
    pacman)
      run_with_optional_sudo pacman -Sy --noconfirm pnpm
      ;;
    apk)
      run_with_optional_sudo apk add pnpm
      ;;
    zypper)
      run_with_optional_sudo zypper --non-interactive install pnpm
      ;;
    *)
      return 1
      ;;
  esac
}

install_docker() {
  case "$PKG_MANAGER" in
    brew)
      run_cmd brew install --cask docker
      ;;
    apt-get)
      run_with_optional_sudo apt-get update
      run_with_optional_sudo apt-get install -y docker.io
      ;;
    dnf)
      run_with_optional_sudo dnf install -y docker
      ;;
    yum)
      run_with_optional_sudo yum install -y docker
      ;;
    pacman)
      run_with_optional_sudo pacman -Sy --noconfirm docker
      ;;
    apk)
      run_with_optional_sudo apk add docker
      ;;
    zypper)
      run_with_optional_sudo zypper --non-interactive install docker
      ;;
    *)
      return 1
      ;;
  esac

  if [[ "$DETECTED_OS" == "linux" ]] && command_exists systemctl; then
    run_with_optional_sudo systemctl enable --now docker || true
  fi
}

install_dependency() {
  local dep="$1"
  case "$dep" in
    git) install_git ;;
    node) install_node ;;
    pnpm) install_pnpm ;;
    docker) install_docker ;;
    *) return 1 ;;
  esac
}

print_environment_summary() {
  log_info "Detected OS: ${DETECTED_OS:-unknown}"
  log_info "Detected ARCH: ${DETECTED_ARCH:-unknown}"
  if [[ -n "${PKG_MANAGER:-}" ]]; then
    log_info "Detected package manager: $PKG_MANAGER"
  else
    log_warn "No supported package manager found."
  fi
}

run_full_diagnostics() {
  if [[ "${OPENCLAW_TEST_MODE:-false}" == "true" ]]; then
    log_info "[test-mode] skip full diagnostics probes."
    return 0
  fi

  log_info "Running full diagnostics..."

  if ! check_dns_resolution "www.openclaw.ai"; then
    return "$ERR_DNS"
  fi
  log_success "DNS resolution check passed."

  if ! check_https_connectivity "https://www.openclaw.ai"; then
    return "$ERR_TLS"
  fi
  log_success "HTTPS connectivity check passed."

  if ! check_source_reachability "$OPENCLAW_OFFICIAL_SH_URL"; then
    return "$ERR_SOURCE_UNREACHABLE"
  fi
  log_success "Installer source reachability check passed."

  check_proxy_env

  if ! check_disk_memory; then
    return "$ERR_RESOURCE"
  fi

  check_common_ports

  if ! check_git_installed; then
    return "$ERR_GIT_MISSING"
  fi

  if ! check_node_version; then
    return "$ERR_NODE_VERSION"
  fi

  if ! check_pnpm_version; then
    return "$ERR_PNPM_VERSION"
  fi

  if ! check_docker_daemon; then
    return "$ERR_DOCKER_DAEMON"
  fi

  log_success "Full diagnostics finished."
  return 0
}

run_preflight() {
  detect_os
  detect_arch
  detect_package_manager || true
  print_environment_summary

  if [[ "$DETECTED_OS" == "unsupported" ]]; then
    return "$ERR_UNSUPPORTED_OS"
  fi

  if ! require_install_permission; then
    return "$ERR_PERMISSION"
  fi

  run_full_diagnostics
  return $?
}
