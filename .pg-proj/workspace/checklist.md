# 功能开发 Checklist

## 任务信息

- 任务 ID: openclaw-usage-simplify
- 任务名称: 简化安装脚本使用方式
- 当前阶段: 交付检查
- 测试策略: Bash 自动化测试 + 文档烟雾测试

## 功能清单

| ID  | 功能点 | 已实现 | 单元测试 | UI测试 |
| --- | ------ | ------ | -------- | ------ |
| F1  | install.sh 增加 `--fast` 快装模式 | ✅ | ✅ | - |
| F2  | fast 模式先输出检测摘要再自动继续 | ✅ | ✅ | - |
| F3  | README 首屏提供一条命令入口 | ✅ | ✅ | - |
| F4  | 提供 hosted 分发模板脚本 | ✅ | ✅ | - |
| F5  | 测试覆盖 fast 模式行为 | ✅ | ✅ | - |

## 边界条件

| ID  | 场景 | 已实现 | 单元测试 | UI测试 |
| --- | ---- | ------ | -------- | ------ |
| B1  | `--fast --dry-run` 同时使用 | ✅ | ✅ | - |
| B2  | `curl ... | sh -s -- --fast` 参数可透传 | ✅ | ✅ | - |

## 文件清单

| 文件 | 状态 | 测试文件 | 测试状态 |
| ---- | ---- | -------- | -------- |
| scripts/lib/common.sh | ✅ 已修改 | tests/install.test.sh | ✅ 已通过 |
| install.sh | ✅ 已修改 | tests/install.test.sh | ✅ 已通过 |
| README.md | ✅ 已修改 | tests/readme_smoke.test.sh | ✅ 已通过 |
| templates/hosted-install.sh.template | ✅ 已创建 | tests/readme_smoke.test.sh | ✅ 已通过 |

## 验证状态

| 检查项 | 状态 |
| ------ | ---- |
| 编译通过 | ✅ |
| 单元测试通过 | ✅ |
| UI 测试通过 | - |
| 静态检查通过 | ✅ |

