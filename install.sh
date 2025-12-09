#!/bin/bash

# ==================================================
# 威软科技 (WeiRuan Tech) - VPS Route Test Installer
# ==================================================

# --- 配置区域 (请修改这里) ---
GITHUB_USER="weiruankeji2025"
REPO_NAME="WeiRuan-Route-Pro"
BRANCH="main"
# ---------------------------

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

# 2. 安装系统基础依赖
echo -e "${YELLOW}[1/4] 正在安装系统环境...${RESET}"
if [ -f /etc/debian_version ]; then
    apt-get update -y && apt-get install -y python3 python3-pip curl git
elif [ -f /etc/redhat-release ]; then
    yum install -y python3 python3-pip curl git
fi

# 3. 安装 NextTrace 核心
echo -e "${YELLOW}[2/4] 正在安装核心组件 NextTrace...${RESET}"
if command -v nexttrace &> /dev/null; then
    echo -e "${GREEN}NextTrace 已安装，跳过。${RESET}"
else
    curl nxtrace.org/nt | bash
fi

# 4. 拉取项目代码
echo -e "${YELLOW}[3/4] 正在从 GitHub 拉取最新源码...${RESET}"
WORK_DIR="/opt/${REPO_NAME}"

# 如果目录存在，先删除旧的，确保代码最新
if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

# 使用 Git Clone (如果国内机器慢，脚本会自动尝试)
git clone -b ${BRANCH} https://github.com/${GITHUB_USER}/${REPO_NAME}.git $WORK_DIR

if [ ! -d "$WORK_DIR" ]; then
    echo -e "${RED}[Error] 代码拉取失败！请检查 GitHub 用户名和仓库名是否正确。${RESET}"
    exit 1
fi

# 5. 安装 Python 依赖
echo -e "${YELLOW}[4/4] 正在配置 Python 环境...${RESET}"
cd $WORK_DIR
pip3 install -r requirements.txt

# 6. 设置后台运行
echo -e "${CYAN}正在启动服务...${RESET}"
# 杀掉可能存在的旧进程
pkill -f "app.py"
# 后台运行
nohup python3 app.py > weiruan_log.txt 2>&1 &

echo -e "${CYAN}=============================================================${RESET}"
echo -e "${GREEN}SUCCESS! 安装并启动成功！${RESET}"
echo -e "${CYAN}=============================================================${RESET}"
echo -e "访问地址: ${GREEN}http://$(curl -s ifconfig.me):8888${RESET}"
echo -e "查看日志: tail -f /opt/${REPO_NAME}/weiruan_log.txt"
echo -e "${CYAN}=============================================================${RESET}"
