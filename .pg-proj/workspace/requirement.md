# OpenClaw 安装增强需求规格（Windows 优先 WSL2 + 全量环境检测）

## 1. 背景与目标

在现有一键安装基础上进一步增强：
- Windows 环境优先推荐 WSL2 路径
- 各系统执行全量严格环境检测
- 缺失必须项时自动安装，无法自动安装则中断并给出修复命令

## 2. 用户确认输入（采访结论）

1. Windows 检测到后：先询问确认，再执行 WSL2 安装
2. 检测级别：全量严格（推荐级别）
3. WSL 推荐触发：只要是 Windows 就推荐（可跳过）
4. 缺失必须项策略：严格模式（无法自动安装则中断）
5. WSL 安装后流程：结束并提示重启，用户重跑脚本

## 3. 范围

- Windows:
  - 检测原生环境 + WSL 状态
  - 默认推荐 WSL2，用户确认后可执行 `wsl --install -d Ubuntu`
  - 安装后提示重启并退出
- macOS/Linux:
  - 执行对应平台全量环境检测
  - 自动修复可修复项

## 4. 全量检测清单（必须项）

- 基础信息：OS、架构、Shell、用户权限
- 网络：DNS 解析、HTTPS 连通、官方源可达
- 包管理器：brew/apt/dnf/yum/pacman/apk/zypper/winget/choco
- 开发依赖：Git、Node.js（>=18）、pnpm（>=8）、Docker
- 系统资源：磁盘可用空间、内存
- 端口：常用冲突端口（如 3000/5173/5432/6379）占用情况
- 代理：`HTTP_PROXY/HTTPS_PROXY` 检测
- 平台专项：
  - Windows: WSL 可用性、WSL 版本、Docker Desktop 状态
  - Linux/macOS: Docker daemon/service 状态

## 5. 成功标准

- Windows 用户可在安装器中明确收到 WSL2 推荐与引导
- 全量检测报告覆盖上述必须项并给出状态
- 必须项缺失时：自动安装成功后继续；不能自动安装则中断并输出修复命令
- 失败日志与错误码可定位

## 6. 边界条件

- 企业网络受限（DNS/TLS/代理）
- 无管理员权限
- 无可用包管理器
- WSL 安装要求重启导致流程中断
- Docker 安装但 daemon 未启动
- 版本低于最低要求（Node<18、pnpm<8）

