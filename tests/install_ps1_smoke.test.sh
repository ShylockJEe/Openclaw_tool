#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT_DIR/install.ps1"

if [[ ! -f "$TARGET" ]]; then
  echo "FAIL: install.ps1 not found" >&2
  exit 1
fi

content="$(cat "$TARGET")"

for token in "Param(" "DryRun" "SkipDocker" "Invoke-Preflight" "Invoke-FullDiagnostics" "Prompt-WSLRecommendation" "Install-WSL2" "Skipping WSL2 by user choice" "Install-MissingDependencies" "Show-FixSuggestion"; do
  if [[ "$content" != *"$token"* ]]; then
    echo "FAIL: missing token in install.ps1 -> $token" >&2
    exit 1
  fi
done

echo "PASS: install_ps1_smoke.test.sh"
