# 代码探索（Windows WSL2 + 全量检测增强）

## 1. 现状

- Bash 入口已具备：参数解析、预检、依赖安装、官方安装调用、验证
- PowerShell 入口已具备：Windows 侧预检、依赖安装、官方安装调用、验证
- 测试已具备：Bash 行为测试 + README 烟雾 + PS1 结构检查

## 2. 缺口

1. Windows 分支缺少“WSL2 推荐并交互确认”的流程
2. 预检仍偏基础，缺少全量严格检测项：
   - DNS/TLS/官方源可达性细分
   - 版本下限检查（Node>=18, pnpm>=8）
   - 磁盘/内存检测
   - 端口占用检测
   - 代理环境探测
   - Docker daemon 状态检测
3. 错误码与修复提示未覆盖新增场景
4. 测试尚未覆盖新增全量检测函数与 WSL 推荐分支

## 3. 影响范围

- 主要修改：
  - `install.ps1`
  - `scripts/lib/preflight.sh`
  - `scripts/lib/diagnose.sh`
  - `install.sh`
- 主要新增测试：
  - `tests/install.test.sh` 扩展边界测试
  - `tests/install_ps1_smoke.test.sh` 扩展 token 覆盖

## 4. 风险点

- Windows WSL 安装命令触发后必须重启，流程需显式终止避免假成功
- 各 Linux 发行版资源检测命令差异（free/df/ss/netstat）需兼容
- 端口检测做成告警而非强制失败更稳妥（避免阻断正常安装）

