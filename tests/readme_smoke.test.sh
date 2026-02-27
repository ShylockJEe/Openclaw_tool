#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README_FILE="$ROOT_DIR/README.md"
TEMPLATE_FILE="$ROOT_DIR/templates/hosted-install.sh.template"

if [[ ! -f "$README_FILE" ]]; then
  echo "FAIL: README.md not found" >&2
  exit 1
fi

content="$(cat "$README_FILE")"

for token in "./install.sh" "install.ps1" "--dry-run" "--skip-docker" "openclaw-install.log" "WSL2"; do
  if [[ "$content" != *"$token"* ]]; then
    echo "FAIL: missing token in README.md -> $token" >&2
    exit 1
  fi
done

for token in "curl -fsSL" "--fast" "一条命令" "raw.githubusercontent.com/ShylockJEe/Openclaw_tool/main/install.sh" "| bash -s -- --fast"; do
  if [[ "$content" != *"$token"* ]]; then
    echo "FAIL: missing fast-install token in README.md -> $token" >&2
    exit 1
  fi
done

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "FAIL: hosted template not found -> $TEMPLATE_FILE" >&2
  exit 1
fi

template_content="$(cat "$TEMPLATE_FILE")"
for token in "OPENCLAW_RAW_INSTALL_URL" "--fast" "curl -fsSL" "raw.githubusercontent.com/ShylockJEe/Openclaw_tool/main/install.sh"; do
  if [[ "$template_content" != *"$token"* ]]; then
    echo "FAIL: missing token in hosted template -> $token" >&2
    exit 1
  fi
done

echo "PASS: readme_smoke.test.sh"
