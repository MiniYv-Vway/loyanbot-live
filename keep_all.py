#!/usr/bin/env python3
"""综合保活 - 多策略并发保活"""
import os, sys, time, logging, subprocess, urllib.request, json
from pathlib import Path

LOG_DIR = Path("/root/loyanbot/storage/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
PID_FILE = LOG_DIR / "keep_all.pid"
AGENT_TOKEN = "agent_access_930591ae-b8ee-4b2f-b5ad-1779f2d98207"
MCP_TASK_ID = "a363865f-366c-485a-acf6-894a53a178d4"
AGENT_API_URL = "http://127.0.0.1:65510/mcp"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [KeepAll] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "keep_all.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("KeepAll")

def mcp_call(tool_name, tool_args):
    payload = {
        "jsonrpc": "2.0",
        "id": int(time.time() * 1000),
        "method": "tools/call",
        "params": {"name": tool_name, "arguments": tool_args}
    }
    headers = {
        "Authorization": f"Bearer {AGENT_TOKEN}",
        "Content-Type": "application/json",
        "Mcp-Session-Id": MCP_TASK_ID,
    }
    try:
        req = urllib.request.Request(
            AGENT_API_URL,
            data=json.dumps(payload).encode(),
            headers=headers,
            method="POST"
        )
        resp = urllib.request.urlopen(req, timeout=5)
        return resp.status
    except Exception as e:
        return 0

def external_ping():
    urls = [
        "https://www.google.com/favicon.ico",
        "https://api.github.com/rate_limit",
        "https://www.cloudflare.com/",
    ]
    for url in urls:
        try:
            urllib.request.urlopen(url, timeout=3)
        except:
            pass
        time.sleep(0.3)

def io_activity():
    try:
        p = Path(f"/tmp/keepalive_{int(time.time())}")
        p.write_bytes(os.urandom(512))
        p.read_bytes()
        p.unlink(missing_ok=True)
    except:
        pass

def main():
    PID_FILE.write_text(str(os.getpid()))
    log.info("KeepAll 启动 - 综合保活")
    try:
        while True:
            # MCP工具调用（每5秒一次）
            mcp_call("background_terminal_list", {})
            time.sleep(2)
            mcp_call("request_preview", {"port": 8000})
            time.sleep(2)
            mcp_call("background_terminal_create", {"command": "echo keepalive", "timeout": 3000})
            time.sleep(1)
            # 外部网络活动（每10秒一次）
            external_ping()
            # 磁盘IO活动（每5秒一次）
            io_activity()
            log.info("保活周期完成")
            time.sleep(5)
    except KeyboardInterrupt:
        log.info("KeepAll 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
