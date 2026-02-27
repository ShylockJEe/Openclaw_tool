# 代码探索（简化使用方式）

## 现状

- install.sh 已支持详细参数，但缺少“fast 一键模式”。
- README 有较多说明，首屏指令可以再压缩。
- 当前没有可直接用于部署分发的入口模板文件。

## 可改进点

1. 增加 `--fast` 参数：
   - 内部自动开启 `--verbose`、默认自动继续，不增加多余交互。
2. 增加快速摘要输出函数，确保“先检测摘要再自动继续”。
3. 增加可部署模板（host 后直接 curl 入口）。

## 影响文件

- `scripts/lib/common.sh`（参数与帮助）
- `install.sh`（fast 行为与摘要）
- `README.md`（最短命令优先）
- 新增 `templates/hosted-install.sh.template`
- 更新测试用例

