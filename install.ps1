Param(
    [switch]$DryRun,
    [switch]$AllowSudo = $true,
    [switch]$SkipNode,
    [switch]$SkipPnpm,
    [switch]$SkipDocker,
    [switch]$VerboseMode,
    [string]$OfficialUrl = "https://www.openclaw.ai/install.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:LogFile = Join-Path (Get-Location) "openclaw-install.log"

$ERR_UNKNOWN = 1
$ERR_NETWORK = 20
$ERR_UNSUPPORTED_OS = 21
$ERR_NO_PACKAGE_MANAGER = 22
$ERR_PERMISSION = 23
$ERR_DNS = 24
$ERR_TLS = 25
$ERR_SOURCE_UNREACHABLE = 26
$ERR_GIT_MISSING = 27
$ERR_NODE_VERSION = 28
$ERR_PNPM_VERSION = 29
$ERR_RESOURCE = 30
$ERR_DOCKER_DAEMON = 31
$ERR_NODE_INSTALL = 40
$ERR_PNPM_INSTALL = 41
$ERR_DOCKER_INSTALL = 42
$ERR_OFFICIAL_INSTALLER = 50
$ERR_VERIFY = 60
$ERR_WSL_REBOOT_REQUIRED = 70
$ERR_WSL_INSTALL_FAILED = 71

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $Script:LogFile -Value $line
}

function Write-Info { param([string]$Message) Write-Log -Level "INFO" -Message $Message }
function Write-Warn { param([string]$Message) Write-Log -Level "WARN" -Message $Message }
function Write-ErrorLog { param([string]$Message) Write-Log -Level "ERROR" -Message $Message }
function Write-Ok { param([string]$Message) Write-Log -Level "OK" -Message $Message }

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsWindowsHost {
    $isWindowsFlag = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
    if ($isWindowsFlag) {
        return [bool]$IsWindows
    }
    return ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
}

function Test-IsAdmin {
    if (-not (Test-IsWindowsHost)) {
        return $true
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-MajorVersion {
    param([string]$VersionText)

    if ([string]::IsNullOrWhiteSpace($VersionText)) {
        return -1
    }

    $clean = ($VersionText.Trim() -replace "^[vV]", "")
    if ($clean -match "^(\d+)") {
        return [int]$Matches[1]
    }
    return -1
}

function Show-FixSuggestion {
    param([int]$Code)

    switch ($Code) {
        $ERR_NETWORK {
            Write-Host "修复建议:"
            Write-Host "1. 检查网络: Test-NetConnection www.openclaw.ai -Port 443"
            Write-Host "2. 代理环境先配置再执行安装"
            break
        }
        $ERR_PERMISSION {
            Write-Host "修复建议:"
            Write-Host "1. 请用管理员身份运行 PowerShell"
            Write-Host "2. 或执行: Start-Process PowerShell -Verb RunAs"
            break
        }
        $ERR_DNS {
            Write-Host "修复建议:"
            Write-Host "1. 执行 Resolve-DnsName www.openclaw.ai 检查 DNS"
            Write-Host "2. 企业网络场景先配置 DNS 或代理"
            break
        }
        $ERR_TLS {
            Write-Host "修复建议:"
            Write-Host "1. 执行 Invoke-WebRequest https://www.openclaw.ai -Method Head"
            Write-Host "2. 检查系统时间与证书链"
            break
        }
        $ERR_SOURCE_UNREACHABLE {
            Write-Host "修复建议:"
            Write-Host "1. 检查安装源是否可达: $OfficialUrl"
            Write-Host "2. 受限网络可指定镜像源后重试"
            break
        }
        $ERR_GIT_MISSING {
            Write-Host "修复建议:"
            Write-Host "1. 安装 Git: winget install --id Git.Git"
            Write-Host "2. 验证: git --version"
            break
        }
        $ERR_NODE_VERSION {
            Write-Host "修复建议:"
            Write-Host "1. 升级 Node.js 到 >= 18"
            Write-Host "2. 验证: node -v"
            break
        }
        $ERR_PNPM_VERSION {
            Write-Host "修复建议:"
            Write-Host "1. 升级 pnpm 到 >= 8: npm install -g pnpm"
            Write-Host "2. 验证: pnpm -v"
            break
        }
        $ERR_RESOURCE {
            Write-Host "修复建议:"
            Write-Host "1. 磁盘空闲 >= 5GB，内存 >= 4GB"
            Write-Host "2. 清理磁盘并关闭高占用程序后重试"
            break
        }
        $ERR_DOCKER_DAEMON {
            Write-Host "修复建议:"
            Write-Host "1. 启动 Docker Desktop 并等待初始化完成"
            Write-Host "2. 验证: docker info"
            break
        }
        $ERR_NODE_INSTALL {
            Write-Host "修复建议:"
            Write-Host "1. 手工安装 Node.js >= 18: https://nodejs.org/"
            break
        }
        $ERR_PNPM_INSTALL {
            Write-Host "修复建议:"
            Write-Host "1. 执行 npm install -g pnpm"
            break
        }
        $ERR_DOCKER_INSTALL {
            Write-Host "修复建议:"
            Write-Host "1. 安装 Docker Desktop 并启动一次"
            break
        }
        $ERR_OFFICIAL_INSTALLER {
            Write-Host "修复建议:"
            Write-Host "1. 手工执行官方命令: irm https://www.openclaw.ai/install.ps1 | iex"
            break
        }
        $ERR_VERIFY {
            Write-Host "修复建议:"
            Write-Host "1. 执行 git --version / node -v / pnpm -v / docker --version 检查"
            break
        }
        $ERR_WSL_INSTALL_FAILED {
            Write-Host "修复建议:"
            Write-Host "1. 以管理员身份执行: wsl --install -d Ubuntu"
            Write-Host "2. 安装完成后重启系统并重新运行安装器"
            break
        }
        default {
            Write-Host "修复建议: 查看 openclaw-install.log 与官方文档 https://docs.openclaw.ai/start/getting-started"
        }
    }
}

function Test-DnsResolution {
    try {
        if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
            $null = Resolve-DnsName -Name "www.openclaw.ai" -ErrorAction Stop
            return $true
        }
        $null = nslookup www.openclaw.ai 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-HttpsConnectivity {
    try {
        $null = Invoke-WebRequest -Uri "https://www.openclaw.ai" -Method Head -UseBasicParsing -TimeoutSec 10
        return $true
    } catch {
        return $false
    }
}

function Test-SourceReachability {
    try {
        $null = Invoke-WebRequest -Uri $OfficialUrl -Method Head -UseBasicParsing -TimeoutSec 10
        return $true
    } catch {
        return $false
    }
}

function Test-ProxyEnv {
    if ($env:HTTP_PROXY -or $env:HTTPS_PROXY -or $env:http_proxy -or $env:https_proxy) {
        Write-Info "Proxy environment detected."
    } else {
        Write-Info "Proxy environment not set."
    }
    return $true
}

function Test-DiskMemory {
    $minDiskGb = 5
    $minMemGb = 4
    if ($env:OPENCLAW_MIN_DISK_GB) {
        $minDiskGb = [int]$env:OPENCLAW_MIN_DISK_GB
    }
    if ($env:OPENCLAW_MIN_MEM_GB) {
        $minMemGb = [int]$env:OPENCLAW_MIN_MEM_GB
    }

    try {
        $driveName = "C"
        if ($env:SystemDrive) {
            $driveName = $env:SystemDrive.TrimEnd(":")
        }
        $drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
        if ($drive) {
            $freeDiskGb = [math]::Floor($drive.Free / 1GB)
            if ($freeDiskGb -lt $minDiskGb) {
                Write-ErrorLog "Disk available ${freeDiskGb}GB is below required ${minDiskGb}GB."
                return $false
            }
            Write-Ok "Disk check passed (${freeDiskGb}GB available)."
        } else {
            Write-Warn "Cannot detect free disk size."
        }
    } catch {
        Write-Warn "Disk check failed unexpectedly: $($_.Exception.Message)"
    }

    try {
        if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
            $totalMemBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
            if ($totalMemBytes) {
                $memGb = [math]::Ceiling(([double]$totalMemBytes) / 1GB)
                if ($memGb -lt $minMemGb) {
                    Write-ErrorLog "Memory ${memGb}GB is below required ${minMemGb}GB."
                    return $false
                }
                Write-Ok "Memory check passed (${memGb}GB total)."
            }
        } else {
            Write-Warn "Cannot detect memory size automatically."
        }
    } catch {
        Write-Warn "Memory check failed unexpectedly: $($_.Exception.Message)"
    }

    return $true
}

function Test-CommonPorts {
    $ports = @(3000, 5173, 5432, 6379)
    $occupied = @()

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        foreach ($port in $ports) {
            $hit = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
            if ($hit) { $occupied += $port }
        }
    } else {
        $netstatOutput = netstat -ano 2>$null
        foreach ($port in $ports) {
            if ($netstatOutput -match "[:\.]$port\s") { $occupied += $port }
        }
    }

    if ($occupied.Count -gt 0) {
        Write-Warn "Common ports already in use: $($occupied -join ',')"
    } else {
        Write-Ok "Common ports check passed."
    }

    return $true
}

function Test-GitInstalled {
    if (Test-Command "git") {
        Write-Ok "Git detected."
        return $true
    }
    Write-ErrorLog "Git is required but not installed."
    return $false
}

function Test-NodeVersion {
    if (-not (Test-Command "node")) {
        Write-Warn "Node.js not installed yet, will attempt auto-install."
        return $true
    }
    $major = Get-MajorVersion -VersionText ((& node -v).Trim())
    if ($major -lt 18) {
        Write-ErrorLog "Node.js major version is below 18."
        return $false
    }
    Write-Ok "Node.js version check passed."
    return $true
}

function Test-PnpmVersion {
    if (-not (Test-Command "pnpm")) {
        Write-Warn "pnpm not installed yet, will attempt auto-install."
        return $true
    }
    $major = Get-MajorVersion -VersionText ((& pnpm -v).Trim())
    if ($major -lt 8) {
        Write-ErrorLog "pnpm major version is below 8."
        return $false
    }
    Write-Ok "pnpm version check passed."
    return $true
}

function Test-DockerDaemon {
    if ($SkipDocker) {
        Write-Info "Skip Docker daemon check by user option."
        return $true
    }

    if (-not (Test-Command "docker")) {
        Write-Warn "Docker not installed yet, will attempt auto-install."
        return $true
    }

    try {
        & docker info *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Docker daemon check passed."
            return $true
        }
    } catch {
    }

    Write-ErrorLog "Docker command exists but daemon is not reachable."
    return $false
}

function Invoke-FullDiagnostics {
    Write-Info "Running full diagnostics..."

    if (-not (Test-DnsResolution)) { return $ERR_DNS }
    Write-Ok "DNS resolution check passed."

    if (-not (Test-HttpsConnectivity)) { return $ERR_TLS }
    Write-Ok "HTTPS connectivity check passed."

    if (-not (Test-SourceReachability)) { return $ERR_SOURCE_UNREACHABLE }
    Write-Ok "Installer source reachability check passed."

    $null = Test-ProxyEnv
    if (-not (Test-DiskMemory)) { return $ERR_RESOURCE }
    $null = Test-CommonPorts

    if (-not (Test-GitInstalled)) { return $ERR_GIT_MISSING }
    if (-not (Test-NodeVersion)) { return $ERR_NODE_VERSION }
    if (-not (Test-PnpmVersion)) { return $ERR_PNPM_VERSION }
    if (-not (Test-DockerDaemon)) { return $ERR_DOCKER_DAEMON }

    Write-Ok "Full diagnostics finished."
    return 0
}

function Test-WSLVersion2 {
    try {
        $output = (& wsl -l -v 2>$null | Out-String)
        return ($output -match "\s2\s")
    } catch {
        return $false
    }
}

function Install-WSL2 {
    if (-not (Test-Command "wsl")) {
        return $false
    }

    if ($DryRun) {
        Write-Info "[dry-run] wsl --install -d Ubuntu"
        return $true
    }

    & wsl --install -d Ubuntu
    return ($LASTEXITCODE -eq 0)
}

function Prompt-WSLRecommendation {
    if (-not (Test-IsWindowsHost)) {
        return 0
    }

    if (Test-WSLVersion2) {
        Write-Ok "WSL2 already configured."
        return 0
    }

    Write-Warn "Detected native Windows host. WSL2 is strongly recommended for OpenClaw."
    Write-Host "Recommended command: wsl --install -d Ubuntu"
    Write-Host "You can continue native Windows install by choosing n."

    $answer = $env:OPENCLAW_WSL_PROMPT_RESPONSE
    if ([string]::IsNullOrWhiteSpace($answer)) {
        $answer = Read-Host "Install WSL2 now? [Y/n]"
    }

    if ([string]::IsNullOrWhiteSpace($answer) -or $answer -match "^(y|yes)$") {
        if (Install-WSL2) {
            Write-Ok "WSL2 installation triggered. Reboot Windows, then rerun this installer."
            return $ERR_WSL_REBOOT_REQUIRED
        }
        return $ERR_WSL_INSTALL_FAILED
    }

    Write-Warn "Skipping WSL2 by user choice. Continue native Windows installation."
    return 0
}

function Invoke-Preflight {
    Write-Info "Running preflight checks..."

    if ($AllowSudo -and -not (Test-IsAdmin) -and -not $DryRun) {
        return $ERR_PERMISSION
    }

    if (-not (Test-Command "winget") -and -not (Test-Command "choco")) {
        Write-Warn "Neither winget nor choco found. Auto-install may be limited."
    }

    return (Invoke-FullDiagnostics)
}

function Install-WithPackageManager {
    param(
        [string]$WingetId,
        [string]$ChocoName
    )

    if ($DryRun) {
        Write-Info "[dry-run] install $WingetId / $ChocoName"
        return $true
    }

    if (Test-Command "winget") {
        & winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements
        return ($LASTEXITCODE -eq 0)
    }

    if (Test-Command "choco") {
        & choco install $ChocoName -y
        return ($LASTEXITCODE -eq 0)
    }

    return $false
}

function Install-MissingDependencies {
    if (-not (Test-Command "git")) {
        Write-Info "Installing Git..."
        if (-not (Install-WithPackageManager -WingetId "Git.Git" -ChocoName "git")) {
            return $ERR_GIT_MISSING
        }
    }

    if (-not $SkipNode -and -not (Test-Command "node")) {
        Write-Info "Installing Node.js..."
        if (-not (Install-WithPackageManager -WingetId "OpenJS.NodeJS.LTS" -ChocoName "nodejs-lts")) {
            return $ERR_NODE_INSTALL
        }
    }

    if (-not $SkipPnpm -and -not (Test-Command "pnpm")) {
        Write-Info "Installing pnpm..."
        if ($DryRun) {
            Write-Info "[dry-run] npm install -g pnpm"
        } else {
            if (-not (Test-Command "npm")) {
                return $ERR_PNPM_INSTALL
            }
            & npm install -g pnpm
            if ($LASTEXITCODE -ne 0) {
                return $ERR_PNPM_INSTALL
            }
        }
    }

    if (-not $SkipDocker -and -not (Test-Command "docker")) {
        Write-Info "Installing Docker Desktop..."
        if (-not (Install-WithPackageManager -WingetId "Docker.DockerDesktop" -ChocoName "docker-desktop")) {
            return $ERR_DOCKER_INSTALL
        }
    }

    return 0
}

function Invoke-OfficialInstaller {
    if ($env:OPENCLAW_SKIP_OFFICIAL -eq "true") {
        Write-Warn "OPENCLAW_SKIP_OFFICIAL=true, skip official installer."
        return 0
    }

    if ($DryRun) {
        Write-Info "[dry-run] invoke official installer from $OfficialUrl"
        return 0
    }

    try {
        $tmp = Join-Path $env:TEMP "openclaw-official.ps1"
        Invoke-WebRequest -Uri $OfficialUrl -OutFile $tmp -UseBasicParsing
        & powershell -ExecutionPolicy Bypass -File $tmp
        if ($LASTEXITCODE -ne 0) {
            return $ERR_OFFICIAL_INSTALLER
        }
    } catch {
        return $ERR_OFFICIAL_INSTALLER
    }

    return 0
}

function Test-Installation {
    if (-not (Test-Command "git")) { return $ERR_VERIFY }
    if (-not $SkipNode -and -not (Test-Command "node")) { return $ERR_VERIFY }
    if (-not $SkipPnpm -and -not (Test-Command "pnpm")) { return $ERR_VERIFY }
    if (-not $SkipDocker -and -not (Test-Command "docker")) { return $ERR_VERIFY }
    if (-not (Test-NodeVersion)) { return $ERR_NODE_VERSION }
    if (-not (Test-PnpmVersion)) { return $ERR_PNPM_VERSION }
    if (-not (Test-DockerDaemon)) { return $ERR_DOCKER_DAEMON }
    return 0
}

Write-Host "===================================="
Write-Host " OpenClaw Smart Installer (Wrapper)"
Write-Host "===================================="
Write-Host "PowerShell options: -DryRun (equivalent to --dry-run), -SkipDocker (equivalent to --skip-docker)"

if ($VerboseMode) {
    Write-Info "Verbose mode enabled."
}

$wslCode = Prompt-WSLRecommendation
if ($wslCode -eq $ERR_WSL_REBOOT_REQUIRED) {
    Write-Ok "Please reboot Windows and rerun install.ps1."
    exit 0
}
if ($wslCode -ne 0) {
    Write-ErrorLog "WSL2 step failed with code=$wslCode"
    Show-FixSuggestion -Code $wslCode
    exit $wslCode
}

$code = Invoke-Preflight
if ($code -ne 0) {
    Write-ErrorLog "Preflight failed with code=$code"
    Show-FixSuggestion -Code $code
    exit $code
}

if ($DryRun) {
    Write-Ok "Dry-run completed."
    exit 0
}

$code = Install-MissingDependencies
if ($code -ne 0) {
    Write-ErrorLog "Dependency install failed with code=$code"
    Show-FixSuggestion -Code $code
    exit $code
}

$code = Invoke-OfficialInstaller
if ($code -ne 0) {
    Write-ErrorLog "Official installer failed with code=$code"
    Show-FixSuggestion -Code $code
    exit $code
}

$code = Test-Installation
if ($code -ne 0) {
    Write-ErrorLog "Verification failed with code=$code"
    Show-FixSuggestion -Code $code
    exit $code
}

Write-Ok "OpenClaw installation completed."
Write-Host "Next steps:"
Write-Host "1. Read docs: https://docs.openclaw.ai/start/getting-started"
Write-Host "2. Start OpenClaw as documented."
