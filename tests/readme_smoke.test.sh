#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README_FILE="$ROOT_DIR/README.md"

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

echo "PASS: readme_smoke.test.sh"
