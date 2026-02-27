# 技术方案（简化脚本使用）

## 目标

给用户一个网好时可直接执行的一条命令入口，同时保持仓库脚本可审计性。

## 方案

1. Bash 新增 `--fast`：
- 启用快装模式标志 `OPENCLAW_FAST_MODE=true`
- 输出快速检测摘要后自动继续
- 仅保留 Windows 侧 WSL 确认（由 install.ps1 控制）

2. 输出简化
- 主流程中增加 `print_quick_summary`
- 快装模式下减少解释性文案，保留关键步骤和失败建议

3. 分发模板
- 新增 `templates/hosted-install.sh.template`
- 提供一条命令示例：
  - `curl -fsSL https://<your-domain>/install.sh | sh -s -- --fast`

4. 测试
- 新增 fast 参数行为测试
- README smoke test 加入 fast 命令检查

