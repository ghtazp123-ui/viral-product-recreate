#!/usr/bin/env bash
# viral-product-recreate 一键安装器（各自账号版）
# 用法：把整个 viral-product-recreate 文件夹发给同事，让同事在文件夹内执行：
#   chmod +x install.sh && ./install.sh
# 脚本会：①装 creatok CLI ②装 ffmpeg ③把 skill 注册进 WorkBuddy ④写入每人自己的 CREATOK_API_KEY
set -euo pipefail

echo "== viral-product-recreate 安装器（各自账号版）=="

# 1) Node.js 检查（装 creatok 需要 npm）
if ! command -v node >/dev/null 2>&1; then
  echo "错误：未检测到 Node.js。请先安装 Node.js LTS (https://nodejs.org)，再运行本脚本。"
  exit 1
fi
echo "Node: $(node -v)"

# 2) 安装 creatok CLI
if command -v creatok >/dev/null 2>&1; then
  echo "creatok 已安装：$(creatok --version 2>/dev/null || echo '')"
else
  echo "正在安装 creatok CLI (npm -g @creatok/cli)..."
  npm install -g @creatok/cli@latest
fi

# 3) 安装 ffmpeg
if command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg 已安装：$(ffmpeg -version | head -1)"
else
  echo "未检测到 ffmpeg，尝试安装..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew >/dev/null 2>&1; then brew install ffmpeg; else echo "请先安装 Homebrew (https://brew.sh) 或手动安装 ffmpeg"; fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update && sudo apt-get install -y ffmpeg 2>/dev/null || echo "请手动安装 ffmpeg (apt/dnf/yum)"
  fi
fi

# 4) 把本 skill 注册进 WorkBuddy（用户级 skills 目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.workbuddy/skills"
mkdir -p "$SKILLS_DIR"
TARGET="$SKILLS_DIR/viral-product-recreate"
rm -rf "$TARGET"
cp -R "$SCRIPT_DIR" "$TARGET"
echo "已安装 skill 到 $TARGET"

# 5) 写入每人自己的 API Key（用户级 shell 配置，持久化）
read -rsp "请输入你的 CREATOK_API_KEY（各自账号，从 CreatOK 后台获取，输入不显示）: " APIKEY
echo
if [[ -n "$APIKEY" ]]; then
  SHELL_RC="$HOME/.zshrc"
  [[ "$SHELL" == *bash* ]] && SHELL_RC="$HOME/.bashrc"
  grep -q 'CREATOK_API_KEY=' "$SHELL_RC" 2>/dev/null && sed -i.bak '/CREATOK_API_KEY=/d' "$SHELL_RC"
  printf 'export CREATOK_API_KEY="%s"\n' "$APIKEY" >> "$SHELL_RC"
  export CREATOK_API_KEY="$APIKEY"
  echo "已写入 $SHELL_RC（重开终端或执行 source $SHELL_RC 生效）"
else
  echo "未输入 key，跳过。稍后手动 export CREATOK_API_KEY=... 即可。"
fi

# 6) 验证
echo "验证账户与余额："
creatok account show || echo "验证失败，请检查 key 与网络"
echo ""
echo "完成！在 WorkBuddy 中直接说：『换品复刻这个爆款 + 你的产品图』即可调用本 skill。"
