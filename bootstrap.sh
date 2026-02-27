#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="${OPENCLAW_REPO_OWNER:-ShylockJEe}"
REPO_NAME="${OPENCLAW_REPO_NAME:-Openclaw_tool}"
REPO_REF="${OPENCLAW_REPO_REF:-main}"
RAW_BASE_URL="${OPENCLAW_RAW_BASE_URL:-https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_REF}}"
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

mkdir -p "$WORK_DIR/scripts/lib"

for rel in "install.sh" "scripts/lib/common.sh" "scripts/lib/diagnose.sh" "scripts/lib/preflight.sh"; do
  src="${RAW_BASE_URL}/${rel}"
  dest="${WORK_DIR}/${rel}"
  if ! download_file "$src" "$dest"; then
    if [[ $? -eq 127 ]]; then
      echo "ERROR: curl/wget not found. Please install curl first."
    else
      echo "ERROR: failed to download ${src}"
    fi
    exit 1
  fi
done

chmod +x "$WORK_DIR/install.sh"

if [[ $# -eq 0 ]]; then
  set -- --fast
fi

bash "$WORK_DIR/install.sh" "$@"
