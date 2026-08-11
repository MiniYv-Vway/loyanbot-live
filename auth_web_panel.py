#!/usr/bin/env python3
"""
写入授权状态面板 - Web 版
提供 HTTP 接口查看授权状态和违规情况
"""

import http.server
import json
import os
import sys
from datetime import datetime
from pathlib import Path

# 配置
LOG_DIR = "/root/loyanbot/storage/logs"
AUTH_FILE = "/root/loyanbot/storage/active_authorizations.json"
COUNT_FILE = "/root/loyanbot/storage/violation_count"
PANIC_FILE = "/root/loyanbot/storage/panic_mode.flag"
MONITOR_LOG = f"{LOG_DIR}/violation_monitor.log"
SKILL_FILE = "/root/.codingmatrix/project-tpl/.ai-ready/skills/no-unauthorized-write/SKILL.md"

class AuthStatusHandler(http.server.BaseHTTPRequestHandler):
    """处理 HTTP 请求"""
    
    def log_message(self, format, *args):
        """静默日志"""
        pass
    
    def do_GET(self):
        """处理 GET 请求"""
        if self.path == '/' or self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            html = self.generate_html()
            self.wfile.write(html.encode('utf-8'))
        elif self.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json; charset=utf-8')
            self.end_headers()
            status = self.get_status()
            self.wfile.write(json.dumps(status, ensure_ascii=False, indent=2).encode('utf-8'))
        elif self.path == '/api/logs':
            self.send_response(200)
            self.send_header('Content-type', 'application/json; charset=utf-8')
            self.end_headers()
            logs = self.get_recent_logs()
            self.wfile.write(json.dumps(logs, ensure_ascii=False, indent=2).encode('utf-8'))
        elif self.path == '/api/violations':
            self.send_response(200)
            self.send_header('Content-type', 'application/json; charset=utf-8')
            self.end_headers()
            violations = self.get_violations()
            self.wfile.write(json.dumps(violations, ensure_ascii=False, indent=2).encode('utf-8'))
        else:
            self.send_error(404)
    
    def get_status(self):
        """获取当前状态"""
        status = {
            "current_auth": self.get_auth_status(),
            "last_auth_time": self.get_last_auth_time(),
            "panic_mode": self.get_panic_status(),
            "violation_count": self.get_violation_count(),
            "last_violation_time": self.get_last_violation_time(),
            "skill_loaded": self.check_skill_loaded(),
            "monitor_running": self.check_monitor_running(),
            "timestamp": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        return status
    
    def get_auth_status(self):
        """获取授权状态"""
        if os.path.exists(AUTH_FILE) and os.path.getsize(AUTH_FILE) > 0:
            try:
                with open(AUTH_FILE, 'r') as f:
                    content = f.read().strip()
                    if '"authorized": true' in content:
                        return "已授权"
                    else:
                        return "未授权"
            except:
                return "无授权"
        return "无授权"
    
    def get_last_auth_time(self):
        """获取最后授权时间"""
        if os.path.exists(AUTH_FILE) and os.path.getsize(AUTH_FILE) > 0:
            try:
                with open(AUTH_FILE, 'r') as f:
                    content = f.read().strip()
                    import re
                    match = re.search(r'"time": "([^"]+)"', content)
                    if match:
                        return match.group(1)
            except:
                pass
        return "--"
    
    def get_panic_status(self):
        """获取恐慌模式状态"""
        if os.path.exists(PANIC_FILE):
            return "已暂停"
        return "正常"
    
    def get_violation_count(self):
        """获取违规次数"""
        if os.path.exists(COUNT_FILE):
            try:
                with open(COUNT_FILE, 'r') as f:
                    return int(f.read().strip())
            except:
                pass
        return "0"
    
    def get_last_violation_time(self):
        """获取最后违规时间"""
        if os.path.exists(MONITOR_LOG):
            try:
                with open(MONITOR_LOG, 'r') as f:
                    lines = f.readlines()
                    for line in reversed(lines):
                        if '违规' in line or '违规监控' in line or '恐慌' in line:
                            import re
                            match = re.search(r'^\[(.*?)\]', line)
                            if match:
                                return match.group(1)
            except:
                pass
        return "--"
    
    def check_skill_loaded(self):
        """检查 skill 是否加载"""
        if os.path.exists(SKILL_FILE):
            try:
                with open(SKILL_FILE, 'r') as f:
                    content = f.read()
                    if '强制检查点' in content and 'priority: 最高' in content:
                        return True
            except:
                pass
        return False
    
    def check_monitor_running(self):
        """检查监控脚本是否运行"""
        try:
            import subprocess
            result = subprocess.run(['pgrep', '-f', 'violation_monitor.sh'], capture_output=True, text=True)
            return result.returncode == 0
        except:
            return False
    
    def get_recent_logs(self):
        """获取最近日志"""
        if os.path.exists(MONITOR_LOG):
            try:
                with open(MONITOR_LOG, 'r') as f:
                    lines = f.readlines()
                    return [line.strip() for line in lines[-10:]]
            except:
                pass
        return []
    
    def get_violations(self):
        """获取违规记录"""
        violations = []
        if os.path.exists(MONITOR_LOG):
            try:
                with open(MONITOR_LOG, 'r') as f:
                    for line in f:
                        if '违规检测' in line:
                            violations.append(line.strip())
            except:
                pass
        return violations[-20:]  # 返回最近20条
    
    def generate_html(self):
        """生成 HTML 页面"""
        status = self.get_status()
        logs = self.get_recent_logs()
        
        # 恐慌模式颜色
        panic_color = "#ff4444" if status["panic_mode"] == "已暂停" else "#4CAF50"
        # 授权状态颜色
        auth_color = "#4CAF50" if status["current_auth"] == "已授权" else "#ff9800" if status["current_auth"] == "未授权" else "#999"
        
        html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>写入授权状态面板</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
        }}
        h1 {{
            color: white;
            text-align: center;
            margin-bottom: 30px;
            font-size: 28px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }}
        .card {{
            background: white;
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }}
        .card-title {{
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 2px solid #f0f0f0;
        }}
        .status-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
        }}
        .status-item {{
            background: #f8f9fa;
            border-radius: 12px;
            padding: 16px;
        }}
        .status-label {{
            font-size: 14px;
            color: #666;
            margin-bottom: 8px;
        }}
        .status-value {{
            font-size: 24px;
            font-weight: bold;
            color: #333;
        }}
        .status-value.auth {{ color: {auth_color}; }}
        .status-value.panic {{ color: {panic_color}; }}
        .status-value.count {{ color: #ff6b6b; }}
        .log-container {{
            max-height: 300px;
            overflow-y: auto;
            background: #1e1e1e;
            border-radius: 8px;
            padding: 12px;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
        }}
        .log-entry {{
            color: #d4d4d4;
            padding: 4px 0;
            border-bottom: 1px solid #333;
        }}
        .log-entry:last-child {{
            border-bottom: none;
        }}
        .auto-refresh {{
            text-align: center;
            color: white;
            margin-top: 20px;
            font-size: 14px;
        }}
        .btn {{
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            margin: 5px;
        }}
        .btn:hover {{
            background: #5568d3;
        }}
    </style>
    <script>
        function refreshStatus() {{
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {{
                    document.getElementById('auth-status').textContent = data.current_auth;
                    document.getElementById('auth-status').className = 'status-value ' + (data.current_auth === '已授权' ? 'auth' : data.current_auth === '未授权' ? 'auth' : '');
                    document.getElementById('panic-status').textContent = data.panic_mode;
                    document.getElementById('panic-status').className = 'status-value panic';
                    document.getElementById('violation-count').textContent = data.violation_count + ' 次';
                    document.getElementById('last-auth').textContent = data.last_auth_time;
                    document.getElementById('last-violation').textContent = data.last_violation_time;
                    document.getElementById('skill-loaded').textContent = data.skill_loaded ? '是' : '否';
                    document.getElementById('monitor-running').textContent = data.monitor_running ? '是' : '否';
                    document.getElementById('timestamp').textContent = data.timestamp;
                }});
            fetch('/api/logs')
                .then(r => r.json())
                .then(logs => {{
                    const container = document.getElementById('log-container');
                    container.innerHTML = logs.map(l => `<div class="log-entry">${{l}}</div>`).join('');
                    container.scrollTop = container.scrollHeight;
                }});
        }}
        setInterval(refreshStatus, 3000);
    </script>
</head>
<body>
    <div class="container">
        <h1>🔒 写入授权状态面板</h1>
        
        <div class="card">
            <div class="card-title">📊 实时状态</div>
            <div class="status-grid">
                <div class="status-item">
                    <div class="status-label">当前授权状态</div>
                    <div class="status-value auth" id="auth-status">加载中...</div>
                </div>
                <div class="status-item">
                    <div class="status-label">最后授权时间</div>
                    <div class="status-value" id="last-auth">--</div>
                </div>
                <div class="status-item">
                    <div class="status-label">恐慌模式</div>
                    <div class="status-value panic" id="panic-status">加载中...</div>
                </div>
                <div class="status-item">
                    <div class="status-label">违规次数</div>
                    <div class="status-value count" id="violation-count">加载中...</div>
                </div>
                <div class="status-item">
                    <div class="status-label">最后违规时间</div>
                    <div class="status-value" id="last-violation">--</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Skill 已加载</div>
                    <div class="status-value" id="skill-loaded">加载中...</div>
                </div>
                <div class="status-item">
                    <div class="status-label">监控运行中</div>
                    <div class="status-value" id="monitor-running">加载中...</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-title">📝 最近监控日志</div>
            <div class="log-container" id="log-container">
                <div class="log-entry">加载中...</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-title">🔧 控制面板</div>
            <div style="text-align: center;">
                <button class="btn" onclick="refreshStatus()">立即刷新</button>
                <button class="btn" onclick="location.reload()">重启页面</button>
            </div>
            <div style="text-align: center; margin-top: 16px; color: #666; font-size: 14px;">
                最后更新: <span id="timestamp">--</span>
            </div>
        </div>
        
        <div class="auto-refresh">
            ⏱️ 每3秒自动刷新
        </div>
    </div>
</body>
</html>"""
        return html

class SilentServer(http.server.HTTPServer):
    """静默服务器"""
    def serve_forever(self, poll_interval=0.1):
        while True:
            self.handle_request()
            import time
            time.sleep(poll_interval)

def main():
    """主函数"""
    port = int(os.environ.get('PORT', 8765))
    server = SilentServer(('', port), AuthStatusHandler)
    print(f"授权状态面板已启动: http://localhost:{port}")
    print("按 Ctrl+C 停止服务")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n服务已停止")
        sys.exit(0)

if __name__ == '__main__':
    main()
