# app.py
import subprocess
from flask import Flask, render_template, Response, request, jsonify
import json
import platform

app = Flask(__name__)

# === 核心配置 ===
# 你可以在这里无限添加测试节点
NODES = [
    {"group": "中国电信", "nodes": [
        {"name": "广州电信 (163)", "ip": "113.108.81.1"},
        {"name": "上海电信 (CN2 GIA)", "ip": "58.32.0.1"},
        {"name": "厦门电信 (CN2)", "ip": "117.28.254.129"}
    ]},
    {"group": "中国联通", "nodes": [
        {"name": "北京联通 (4837)", "ip": "123.125.96.1"},
        {"name": "上海联通 (9929)", "ip": "210.13.66.238"},
        {"name": "四川联通", "ip": "119.6.6.6"}
    ]},
    {"group": "中国移动", "nodes": [
        {"name": "广州移动", "ip": "120.196.165.24"},
        {"name": "上海移动 (CMIN2)", "ip": "221.183.55.22"},
        {"name": "香港移动 (CMI)", "ip": "223.120.2.1"}
    ]},
    {"group": "国际骨干", "nodes": [
        {"name": "Google (Global)", "ip": "8.8.8.8"},
        {"name": "Cloudflare (Anycast)", "ip": "1.1.1.1"},
        {"name": "DMIT (LAX)", "ip": "154.17.12.22"},
        {"name": "Kirino (Tokyo)", "ip": "103.121.208.1"}
    ]}
]

@app.route('/')
def index():
    # 获取本机基本信息
    sys_info = {
        "os": platform.system(),
        "release": platform.release(),
        "node": platform.node()
    }
    return render_template('index.html', nodes=NODES, sys_info=sys_info)

@app.route('/stream_trace')
def stream_trace():
    target = request.args.get('ip')
    if not target:
        return "No Target IP", 400

    def generate():
        # 调用 NextTrace，-q 1 为快速模式
        cmd = ["nexttrace", "-q", "1", target]
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, bufsize=1)
        
        yield "data: [SYSTEM] Initiating Quantum Trace Protocol...\n\n"
        
        for line in process.stdout:
            # 格式化为 SSE (Server-Sent Events) 数据流
            yield f"data: {line}\n\n"
            
        process.stdout.close()
        process.wait()
        yield "data: [SYSTEM] Trace Complete.\n\n"

    return Response(generate(), mimetype='text/event-stream')

if __name__ == '__main__':
    # 监听所有IP，端口8888
    app.run(host='0.0.0.0', port=8888)
