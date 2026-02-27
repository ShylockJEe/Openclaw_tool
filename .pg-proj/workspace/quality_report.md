# 质量报告

## 任务

- openclaw-windows-wsl-first
- Windows 优先 WSL2 与全量环境检测

## 语法与静态检查

- `bash -n install.sh scripts/lib/common.sh scripts/lib/preflight.sh scripts/lib/diagnose.sh tests/install.test.sh tests/readme_smoke.test.sh tests/install_ps1_smoke.test.sh`
  - 结果：通过

## 自动化测试

- `bash tests/install.test.sh`
  - 结果：通过
  - 覆盖：
    - CLI 参数与 dry-run
    - DNS 失败映射（B1）
    - TLS 失败映射（B2）
    - 官方源不可达映射（B3）
    - 权限不足映射
    - Git 缺失映射
    - Node 版本过低映射（B4）
    - pnpm 版本过低映射（B5）
    - Docker daemon 不可达映射（B6）
    - 无包管理器与官方安装器失败映射
    - WSL 环境识别分支

- `bash tests/readme_smoke.test.sh`
  - 结果：通过
  - 覆盖：README 关键命令与 WSL2 文档说明

- `bash tests/install_ps1_smoke.test.sh`
  - 结果：通过
  - 覆盖：PowerShell 脚本关键函数/WSL2 分支标识（含 B7 分支文案）

- `pwsh -NoProfile -File tests/install.ps1.test.ps1`
  - 结果：未执行（当前环境缺少 `pwsh`）
  - 说明：脚本已更新并保留专项测试文件，待 Windows 或含 pwsh 环境补跑

## 结论

- Bash 安装器已具备全量严格检测与错误码修复提示
- Windows 安装器已具备 WSL2 推荐交互与重启后重跑机制
- 当前交付可直接进入真实 Windows 环境做一次 `install.ps1` 实机验证
