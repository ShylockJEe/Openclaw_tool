#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="${OPENCLAW_REPO_OWNER:-ShylockJEe}"
REPO_NAME="${OPENCLAW_REPO_NAME:-Openclaw_tool}"
REPO_REF="${OPENCLAW_REPO_REF:-main}"
RAW_BASE_URL_DEFAULT="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_REF}"
JSDELIVR_BASE_URL_DEFAULT="https://cdn.jsdelivr.net/gh/${REPO_OWNER}/${REPO_NAME}@${REPO_REF}"
WORK_DIR="$(mktemp -d /tmp/openclaw-bootstrap-XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

download_file() {
  local src="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$src" -o "$dest"
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q "$src" -O "$dest"
    return $?
  fi

  return 127
}

download_bundle_from_base() {
  local base="$1"
  local rel src dest

  rm -rf "$WORK_DIR/scripts"
  mkdir -p "$WORK_DIR/scripts/lib"

  for rel in "install.sh" "scripts/lib/common.sh" "scripts/lib/diagnose.sh" "scripts/lib/preflight.sh"; do
    src="${base}/${rel}"
    dest="${WORK_DIR}/${rel}"
    if ! download_file "$src" "$dest"; then
      return $?
    fi
  done

  return 0
}

BASE_CANDIDATES=()
if [[ -n "${OPENCLAW_RAW_BASE_URL:-}" ]]; then
  BASE_CANDIDATES+=("${OPENCLAW_RAW_BASE_URL}")
fi
BASE_CANDIDATES+=("$RAW_BASE_URL_DEFAULT" "$JSDELIVR_BASE_URL_DEFAULT")

DOWNLOAD_OK="false"
for base in "${BASE_CANDIDATES[@]}"; do
  echo "Bootstrap: trying source $base"
  if download_bundle_from_base "$base"; then
    DOWNLOAD_OK="true"
    break
  fi
  rc=$?
  if [[ $rc -eq 127 ]]; then
    echo "ERROR: curl/wget not found. Please install curl first."
    exit 1
  fi
  echo "Bootstrap: source failed -> $base"
done

if [[ "$DOWNLOAD_OK" != "true" ]]; then
  echo "ERROR: all bootstrap sources failed."
  echo "Tried:"
  for base in "${BASE_CANDIDATES[@]}"; do
    echo "  - $base"
  done
  exit 1
fi

chmod +x "$WORK_DIR/install.sh"

if [[ $# -eq 0 ]]; then
  set -- --fast
fi

bash "$WORK_DIR/install.sh" "$@"
