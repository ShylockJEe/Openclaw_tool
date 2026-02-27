# OpenClaw Smart Installer Wrapper

## 一条命令（推荐）

网络正常时，直接执行：

```bash
curl -fsSL https://raw.githubusercontent.com/ShylockJEe/Openclaw_tool/main/bootstrap.sh | bash -s -- --fast
```

说明：
- `--fast` 会先输出快速检测摘要，然后自动继续安装
- Windows 仍会保留一次 WSL2 推荐确认

## 仓库方式（可审计）

```bash
git clone https://github.com/ShylockJEe/Openclaw_tool.git
cd openclaw_tool
./install.sh --fast
```

## Windows

```powershell
.\install.ps1
```

## 常用参数

```bash
./install.sh --fast
./install.sh --dry-run
./install.sh --skip-docker
./install.sh --no-sudo
./install.sh --official-url https://www.openclaw.ai/install.sh
./install.sh --verbose
```

## 全量检测项

- OS / 架构 / 权限 / 包管理器
- DNS 解析、HTTPS 连通、官方源可达
- Git、Node.js（>=18）、pnpm（>=8）、Docker
- 磁盘空间与内存
- 常用端口占用（3000/5173/5432/6379）
- 代理环境变量
- Docker daemon 可用性

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
