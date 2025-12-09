#!/bin/bash

# ==================================================
# 威软科技 (WeiRuan Tech) - VPS Route Test Installer
# ==================================================

# --- 配置区域 ---
GITHUB_USER="你的GitHub用户名" # <--- 记得修改这里
REPO_NAME="weiruan-route-test"
BRANCH="main"
# ----------------

# 定义颜色
GREEN="\033[32m"
RED="\033[31m"
CYAN="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

clear
echo -e "${CYAN}=============================================================${RESET}"
echo -e "${CYAN}    WeiRuan VPS Route Test (威软路由监测) - 一键部署脚本      ${RESET}"
echo -e "${CYAN}=============================================================${RESET}"

# 1. 检测是否为 Root 用户
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[Error] 此脚本必须以 root 身份运行！${RESET}" 
   echo -e "请使用: sudo -i 切换到 root 用户后再试。"
   exit 1
fi

# 2. 安装系统基础依赖 (增加 python3-venv)
echo -e "${YELLOW}[1/5] 正在安装系统环境...${RESET}"
if [ -f /etc/debian_version ]; then
    apt-get update -y
    # Debian 12+ 需要 python3-venv 才能创建虚拟环境
    apt-get install -y python3 python3-pip python3-venv curl git
elif [ -f /etc/redhat-release ]; then
    yum install -y python3 python3-pip curl git
fi

# 3. 安装 NextTrace 核心
echo -e "${YELLOW}[2/5] 正在安装核心组件 NextTrace...${RESET}"
if command -v nexttrace &> /dev/null; then
    echo -e "${GREEN}NextTrace 已安装，跳过。${RESET}"
else
    curl nxtrace.org/nt | bash
fi

# 4. 拉取项目代码
echo -e "${YELLOW}[3/5] 正在从 GitHub 拉取最新源码...${RESET}"
WORK_DIR="/opt/${REPO_NAME}"

if [ -d "$WORK_DIR" ]; then
    echo -e "发现旧目录，正在清理..."
    rm -rf "$WORK_DIR"
fi

git clone -b ${BRANCH} https://github.com/${GITHUB_USER}/${REPO_NAME}.git $WORK_DIR

if [ ! -d "$WORK_DIR" ]; then
    echo -e "${RED}[Error] 代码拉取失败！请检查 GitHub 用户名和仓库名。${RESET}"
    exit 1
fi

# 5. 配置 Python 虚拟环境 (修复 Externally Managed Environment 错误)
echo -e "${YELLOW}[4/5] 正在配置独立运行环境 (Venv)...${RESET}"
cd $WORK_DIR

# 创建虚拟环境文件夹 venv
python3 -m venv venv

# 使用虚拟环境内的 pip 安装依赖
./venv/bin/pip install -r requirements.txt

# 6. 设置后台运行
echo -e "${CYAN}正在启动服务...${RESET}"
# 杀掉旧进程
pkill -f "app.py"

# 注意：这里使用虚拟环境内的 python3 启动
nohup ./venv/bin/python3 app.py > weiruan_log.txt 2>&1 &

echo -e "${CYAN}=============================================================${RESET}"
echo -e "${GREEN}SUCCESS! 安装并启动成功！${RESET}"
echo -e "${CYAN}=============================================================${RESET}"
# 获取公网IP，如果curl失败则尝试其他方式
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)
echo -e "访问地址: ${GREEN}http://${PUBLIC_IP}:8888${RESET}"
echo -e "查看日志: tail -f ${WORK_DIR}/weiruan_log.txt"
echo -e "${CYAN}=============================================================${RESET}"
