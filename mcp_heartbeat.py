#!/usr/bin/env python3
"""MCP心跳 - 通过MCP API保持平台活跃"""
import os, sys, time, logging, urllib.request, json
from pathlib import Path

LOG_DIR = Path("/root/loyanbot/storage/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
PID_FILE = LOG_DIR / "mcp_heartbeat.pid"
AGENT_TOKEN = "agent_access_930591ae-b8ee-4b2f-b5ad-1779f2d98207"
MCP_TASK_ID = "a363865f-366c-485a-acf6-894a53a178d4"
AGENT_API_URL = "http://127.0.0.1:65510/mcp"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [MCPHeartbeat] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "mcp_heartbeat.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("MCPHeartbeat")

def mcp_call(method, params=None, tool_name=None, tool_args=None):
    if tool_name:
        payload = {
            "jsonrpc": "2.0",
            "id": int(time.time() * 1000),
            "method": "tools/call",
            "params": {"name": tool_name, "arguments": tool_args or {}}
        }
    else:
        payload = {
            "jsonrpc": "2.0",
            "id": int(time.time() * 1000),
            "method": method,
            "params": params or {}
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
        data = json.loads(resp.read().decode())
        return resp.status, data
    except Exception as e:
        return 0, str(e)

def main():
    PID_FILE.write_text(str(os.getpid()))
    log.info("MCPHeartbeat 启动")
    try:
        while True:
            # 调用不同的MCP工具模拟活跃
            methods = [
                ("tools/list", None, None, None),
                ("tools/call", None, "background_terminal_list", {}),
                ("tools/call", None, "request_preview", {"port": 8000}),
                ("tools/call", None, "background_terminal_create", {"command": "echo keepalive", "timeout": 5000}),
            ]
            for method, params, tool_name, tool_args in methods:
                status, result = mcp_call(method, params, tool_name, tool_args)
                log.info(f"MCP调用 {method}/{tool_name or ''} -> {status}")
                time.sleep(0.5)
            time.sleep(5)
    except KeyboardInterrupt:
        log.info("MCPHeartbeat 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
