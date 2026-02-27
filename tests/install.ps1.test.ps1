$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root "install.ps1"

if (-not (Test-Path $target)) {
    throw "install.ps1 not found."
}

$content = Get-Content -Path $target -Raw

$requiredTokens = @(
    "--dry-run",
    "--skip-docker",
    "Invoke-Preflight",
    "Invoke-FullDiagnostics",
    "Prompt-WSLRecommendation",
    "Install-WSL2",
    "Skipping WSL2 by user choice",
    "Install-MissingDependencies",
    "Show-FixSuggestion"
)

foreach ($token in $requiredTokens) {
    if (-not $content.Contains($token)) {
        throw "Token missing: $token"
    }
}

Write-Host "PASS: install.ps1.test.ps1"
