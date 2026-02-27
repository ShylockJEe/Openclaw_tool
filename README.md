# OpenClaw Smart Installer Wrapper

这个项目提供 OpenClaw 的增强安装入口，目标是降低多平台环境配置成本：

- 跨平台入口：macOS / Linux / Windows
- Windows 默认推荐 WSL2（可交互确认）
- 全量严格环境检测（网络、源可达、版本下限、资源、端口、代理、Docker daemon）
- 自动检测并尽可能自动安装必须依赖（Git / Node.js / pnpm / Docker）
- 调用官方安装器
- 失败时输出可复制修复建议

## 快速开始

推荐方式（可审计）：

```bash
git clone https://github.com/ShylockJEe/Openclaw_tool.git
cd openclaw_tool
./install.sh
```

快速方式（一行命令）：

```bash
curl -fsSL <your-hosted-install.sh-url> | sh
```

Windows（PowerShell）：

```powershell
.\install.ps1
```

## Windows WSL2 推荐逻辑

- 检测到原生 Windows 时，脚本会提示：是否现在安装 WSL2
- 选择 `Y`：执行 `wsl --install -d Ubuntu`
- 安装命令成功后，脚本会提示“重启系统后重跑安装器”并退出
- 选择 `n`：继续原生 Windows 安装路径

## 常用参数

### Bash

```bash
./install.sh --dry-run
./install.sh --skip-docker
./install.sh --no-sudo
./install.sh --official-url https://www.openclaw.ai/install.sh
./install.sh --verbose
```

### PowerShell

```powershell
.\install.ps1 -DryRun
.\install.ps1 -SkipDocker
.\install.ps1 -OfficialUrl https://www.openclaw.ai/install.ps1
```

## 全量检测项

- OS / 架构 / 权限 / 包管理器
- DNS 解析、HTTPS 连通、官方源可达
- Git、Node.js（>=18）、pnpm（>=8）、Docker
- 磁盘空间与内存
- 常用端口占用（3000/5173/5432/6379）
- 代理环境变量
- Docker daemon 可用性

## 严格模式行为

- 检测到必须项缺失：自动尝试安装
- 无法自动安装或必须项检测失败：中断并输出修复命令

## 失败排查

1. 查看日志文件：`openclaw-install.log`
2. 先做环境干跑：`./install.sh --dry-run`
3. 打开详细日志：`./install.sh --verbose`
4. 官方文档：[Getting Started](https://docs.openclaw.ai/start/getting-started)

## 测试

```bash
bash tests/install.test.sh
bash tests/readme_smoke.test.sh
bash tests/install_ps1_smoke.test.sh
```

如果本机有 PowerShell：

```bash
pwsh -NoProfile -File tests/install.ps1.test.ps1
```
