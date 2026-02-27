#!/usr/bin/env bash

set -euo pipefail

REPO_TARBALL_URL="${OPENCLAW_REPO_TARBALL_URL:-https://codeload.github.com/ShylockJEe/Openclaw_tool/tar.gz/refs/heads/main}"
WORK_DIR="$(mktemp -d /tmp/openclaw-bootstrap-XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_TARBALL_URL" | tar -xz -C "$WORK_DIR"
elif command -v wget >/dev/null 2>&1; then
  wget -qO- "$REPO_TARBALL_URL" | tar -xz -C "$WORK_DIR"
else
  echo "ERROR: curl/wget not found."
  exit 1
fi

PROJECT_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$PROJECT_DIR" ]] || [[ ! -f "$PROJECT_DIR/install.sh" ]]; then
  echo "ERROR: extracted installer not found."
  exit 1
fi

if [[ $# -eq 0 ]]; then
  set -- --fast
fi

bash "$PROJECT_DIR/install.sh" "$@"
