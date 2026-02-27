# 功能开发 Checklist

## 任务信息

- 任务 ID: openclaw-windows-wsl-first
- 任务名称: Windows 优先 WSL2 与全量环境检测
- 当前阶段: 交付检查
- 测试策略: Bash 完整测试 + PS1 结构烟雾测试

## 功能清单

| ID  | 功能点 | 已实现 | 单元测试 | UI测试 |
| --- | ------ | ------ | -------- | ------ |
| F1  | Windows 检测后推荐 WSL2（可交互确认） | ✅ | ✅ | - |
| F2  | 用户确认后执行 `wsl --install -d Ubuntu` | ✅ | ✅ | - |
| F3  | WSL2 安装后提示重启并退出流程 | ✅ | ✅ | - |
| F4  | macOS/Linux/Windows 全量环境检测 | ✅ | ✅ | - |
| F5  | 必须项缺失自动安装，失败则严格中断 | ✅ | ✅ | - |
| F6  | 错误码与修复建议覆盖新增场景 | ✅ | ✅ | - |
| F7  | README 更新（WSL 推荐 + 全量检测说明） | ✅ | ✅ | - |

## 边界条件

| ID  | 场景 | 已实现 | 单元测试 | UI测试 |
| --- | ---- | ------ | -------- | ------ |
| B1  | DNS 解析失败 | ✅ | ✅ | - |
| B2  | HTTPS/TLS 连通失败 | ✅ | ✅ | - |
| B3  | 官方源不可达 | ✅ | ✅ | - |
| B4  | Node 版本低于 18 | ✅ | ✅ | - |
| B5  | pnpm 版本低于 8 | ✅ | ✅ | - |
| B6  | Docker daemon 未启动 | ✅ | ✅ | - |
| B7  | Windows 拒绝安装 WSL2，继续原生流程 | ✅ | ✅ | - |

## 文件清单

| 文件 | 状态 | 测试文件 | 测试状态 |
| ---- | ---- | -------- | -------- |
| install.sh | ✅ 已修改 | tests/install.test.sh | ✅ 已通过 |
| install.ps1 | ✅ 已修改 | tests/install_ps1_smoke.test.sh + tests/install.ps1.test.ps1 | ✅ 烟雾测试通过（pwsh 专项已编写） |
| scripts/lib/preflight.sh | ✅ 已修改 | tests/install.test.sh | ✅ 已通过 |
| scripts/lib/diagnose.sh | ✅ 已修改 | tests/install.test.sh | ✅ 已通过 |
| README.md | ✅ 已修改 | tests/readme_smoke.test.sh | ✅ 已通过 |

## 验证状态

| 检查项 | 状态 |
| ------ | ---- |
| 编译通过 | ✅ |
| 单元测试通过 | ✅ |
| UI 测试通过 | - |
| 静态检查通过 | ✅ |
