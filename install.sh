#!/bin/bash

# 定义颜色
GREEN="\033[32m"
CYAN="\033[36m"
RESET="\033[0m"

echo -e "${CYAN}==============================================${RESET}"
echo -e "${CYAN}    WeiRuan VPS Route Test - One Click Installer   ${RESET}"
echo -e "${CYAN}==============================================${RESET}"

# 1. 安装系统依赖
echo -e "${GREEN}[+] Installing System Dependencies...${RESET}"
if [ -f /etc/debian_version ]; then
    apt-get update && apt-get install -y python3 python3-pip curl
elif [ -f /etc/redhat-release ]; then
    yum install -y python3 python3-pip curl
fi

# 2. 安装 NextTrace (核心组件)
echo -e "${GREEN}[+] Installing NextTrace...${RESET}"
curl nxtrace.org/nt | bash

# 3. 安装 Python 依赖
echo -e "${GREEN}[+] Installing Python Requirements...${RESET}"
pip3 install flask

# 4. 运行提示
echo -e "${CYAN}==============================================${RESET}"
echo -e "${GREEN}Installation Complete!${RESET}"
echo -e "To start the server, run:"
echo -e "${CYAN}python3 app.py${RESET}"
echo -e "Then visit: http://YOUR_VPS_IP:8888"
echo -e "${CYAN}==============================================${RESET}"

# 可选：询问是否立即运行
read -p "Do you want to start the server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nohup python3 app.py > weiruan_log.txt 2>&1 &
    echo -e "${GREEN}Server started in background on port 8888!${RESET}"
fi
