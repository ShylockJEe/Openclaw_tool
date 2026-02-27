#!/usr/bin/env bash

ERR_UNKNOWN=1
ERR_NETWORK=20
ERR_UNSUPPORTED_OS=21
ERR_NO_PACKAGE_MANAGER=22
ERR_PERMISSION=23
ERR_DNS=24
ERR_TLS=25
ERR_SOURCE_UNREACHABLE=26
ERR_GIT_MISSING=27
ERR_NODE_VERSION=28
ERR_PNPM_VERSION=29
ERR_RESOURCE=30
ERR_DOCKER_DAEMON=31
ERR_NODE_INSTALL=40
ERR_PNPM_INSTALL=41
ERR_DOCKER_INSTALL=42
ERR_OFFICIAL_INSTALLER=50
ERR_VERIFY=60

print_fix_suggestion() {
  local code="${1:-$ERR_UNKNOWN}"

  case "$code" in
    "$ERR_NETWORK")
      cat <<'EOF'
修复建议:
1. 检查网络连通性: curl -I https://www.openclaw.ai
2. 如果在企业网络，配置代理后重试:
   export HTTPS_PROXY=http://<proxy-host>:<proxy-port>
3. 使用 --dry-run 先确认环境状态
EOF
      ;;
    "$ERR_UNSUPPORTED_OS")
      cat <<'EOF'
修复建议:
1. 当前系统不在支持范围（macOS/Linux/Windows）
2. Windows 用户请运行 install.ps1
3. Linux 用户建议使用 Ubuntu 22.04+ / Debian 12+ / RHEL 9+
EOF
      ;;
    "$ERR_NO_PACKAGE_MANAGER")
      cat <<'EOF'
修复建议:
1. 安装包管理器后重试:
   - macOS: brew
   - Debian/Ubuntu: apt-get
   - Fedora/RHEL: dnf/yum
2. 或手工安装 Node.js、pnpm、Docker 后重新执行安装脚本
EOF
      ;;
    "$ERR_PERMISSION")
      cat <<'EOF'
修复建议:
1. 以管理员/sudo 权限运行安装脚本
2. 若禁用 sudo，请移除 --no-sudo 或切换到有权限账号
3. Windows 请用“管理员身份运行 PowerShell”
EOF
      ;;
    "$ERR_DNS")
      cat <<'EOF'
修复建议:
1. 检查 DNS 配置是否可解析域名:
   nslookup www.openclaw.ai
2. 企业网络场景请配置公司 DNS 或代理
3. 重新执行安装脚本
EOF
      ;;
    "$ERR_TLS")
      cat <<'EOF'
修复建议:
1. 检查 HTTPS/TLS 连通性:
   curl -I https://www.openclaw.ai
2. 若证书校验失败，检查系统时间与 CA 证书
3. 代理场景下先设置 HTTPS_PROXY
EOF
      ;;
    "$ERR_SOURCE_UNREACHABLE")
      cat <<'EOF'
修复建议:
1. 检查安装源可达性:
   curl -I https://www.openclaw.ai/install.sh
2. 网络受限时可切换网络后重试
3. 若你有镜像源，请通过 --official-url 指向可达地址
EOF
      ;;
    "$ERR_GIT_MISSING")
      cat <<'EOF'
修复建议:
1. 安装 Git:
   - macOS: brew install git
   - Ubuntu/Debian: sudo apt-get install -y git
2. 验证: git --version
EOF
      ;;
    "$ERR_NODE_VERSION")
      cat <<'EOF'
修复建议:
1. 升级 Node.js 到 >= 18:
   node -v
2. 建议使用官方 LTS 版本
EOF
      ;;
    "$ERR_PNPM_VERSION")
      cat <<'EOF'
修复建议:
1. 升级 pnpm 到 >= 8:
   npm install -g pnpm
2. 验证: pnpm -v
EOF
      ;;
    "$ERR_RESOURCE")
      cat <<'EOF'
修复建议:
1. 确保磁盘空闲空间 >= 5GB
2. 确保可用内存 >= 4GB
3. 清理磁盘或关闭占用较高进程后重试
EOF
      ;;
    "$ERR_DOCKER_DAEMON")
      cat <<'EOF'
修复建议:
1. 启动 Docker 服务/桌面端:
   docker info
2. Linux 可执行:
   sudo systemctl enable --now docker
3. Windows/macOS 请先手动打开 Docker Desktop
EOF
      ;;
    "$ERR_NODE_INSTALL")
      cat <<'EOF'
修复建议:
1. 手动安装 Node.js >= 18: https://nodejs.org/
2. 验证安装: node -v
3. 再次执行安装脚本
EOF
      ;;
    "$ERR_PNPM_INSTALL")
      cat <<'EOF'
修复建议:
1. 先确认 npm 可用: npm -v
2. 手动安装 pnpm: npm install -g pnpm
3. 验证安装: pnpm -v
EOF
      ;;
    "$ERR_DOCKER_INSTALL")
      cat <<'EOF'
修复建议:
1. 手动安装 Docker:
   - macOS/Windows: Docker Desktop
   - Linux: Docker Engine
2. 验证安装: docker --version
3. Linux 额外检查 docker 服务:
   sudo systemctl enable --now docker
EOF
      ;;
    "$ERR_OFFICIAL_INSTALLER")
      cat <<'EOF'
修复建议:
1. 检查官方安装脚本地址是否可访问
2. 手动执行官方命令验证:
   curl -fsSL https://www.openclaw.ai/install.sh | sh
3. 查看日志 openclaw-install.log 获取详细报错
EOF
      ;;
    "$ERR_VERIFY")
      cat <<'EOF'
修复建议:
1. 执行以下命令检查:
   node -v
   pnpm -v
   docker --version
2. 重新运行安装脚本（建议加 --verbose）
EOF
      ;;
    *)
      cat <<'EOF'
修复建议:
1. 使用 --verbose 重试获取详细日志
2. 查看 openclaw-install.log
3. 参考官方文档: https://docs.openclaw.ai/start/getting-started
EOF
      ;;
  esac
}
