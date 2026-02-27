# 技术方案（Windows 优先 WSL2 + 全量检测）

## 1. 方案概述

在现有安装器上做增量增强，不推倒重写：
- Windows 分支新增 WSL2 推荐交互（确认后执行安装并提示重启退出）
- Bash 与 PowerShell 两端都增加全量严格检测函数
- 必须项失败时立即中断，并映射到明确错误码+修复建议

## 2. 模块设计

### Bash

1. `scripts/lib/preflight.sh`
- 新增：
  - `check_dns_resolution`
  - `check_https_connectivity`
  - `check_source_reachability`
  - `check_git_installed`
  - `check_node_version`
  - `check_pnpm_version`
  - `check_disk_memory`
  - `check_common_ports`
  - `check_proxy_env`
  - `check_docker_daemon`
  - `run_full_diagnostics`

2. `scripts/lib/diagnose.sh`
- 扩展错误码与修复映射：
  - DNS/TLS/Source 不可达
  - Git 缺失
  - Node/Pnpm 版本过低
  - 系统资源不足
  - Docker daemon 未启动

3. `install.sh`
- 在 preflight 后输出全量检测摘要
- 严格模式下对 FAIL 直接退出

### PowerShell

1. `install.ps1`
- 新增 Windows 推荐 WSL2 流程：
  - `Test-IsWindowsHost`
  - `Test-WSLStatus`
  - `Prompt-WSLRecommendation`
  - `Install-WSL2`（执行 `wsl --install -d Ubuntu`）
- 新增全量检测：
  - DNS/TLS/源可达
  - 版本检查
  - 磁盘/内存
  - 常用端口占用
  - 代理环境
  - Docker Desktop/daemon

## 3. 文件修改清单

- 修改：
  - `install.sh`
  - `install.ps1`
  - `scripts/lib/preflight.sh`
  - `scripts/lib/diagnose.sh`
  - `tests/install.test.sh`
  - `tests/install_ps1_smoke.test.sh`
  - `README.md`

## 4. 测试策略

- Bash 自动化测试新增覆盖：
  - DNS/TLS/source 检测失败映射
  - Node/Pnpm 版本失败映射
  - Docker daemon 未启动映射
  - 全量检测入口执行
- Windows 结构烟雾测试新增 token：
  - `Prompt-WSLRecommendation`
  - `Install-WSL2`
  - `run full diagnostics` 相关函数名

## 5. 兼容性策略

- 保持 Bash 3 兼容（不使用 mapfile）
- 端口检测若工具缺失，降级为 WARN
- dry-run 模式不执行破坏性安装动作

