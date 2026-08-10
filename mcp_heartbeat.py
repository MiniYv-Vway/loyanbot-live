#!/usr/bin/env python3
"""MCP心跳 - 通过MCP API保持平台活跃"""
import os, sys, time, logging, urllib.request, json, fcntl
from pathlib import Path

PID_FILE = Path("/root/loyanbot/storage/logs/mcp_heartbeat.pid")
LOCK_FILE = Path("/root/loyanbot/storage/logs/mcp_heartbeat.lock")
LOG_DIR = Path("/root/loyanbot/storage/logs")
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

def acquire_lock():
    try:
        f = open(LOCK_FILE, 'w')
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        f.write(str(os.getpid()))
        f.flush()
        return f
    except IOError:
        log.info("其他实例正在运行，退出")
        sys.exit(0)

def release_lock(f):
    fcntl.flock(f, fcntl.LOCK_UN)
    f.close()
    LOCK_FILE.unlink(missing_ok=True)

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

def main():
    lock = acquire_lock()
    PID_FILE.write_text(str(os.getpid()))
    log.info("MCPHeartbeat 启动")
    try:
        while True:
            for name, args in [
                ("tools/list", {}),
                ("background_terminal_list", {}),
                ("request_preview", {"port": 8000}),
                ("background_terminal_create", {"command": "echo keepalive", "timeout": 3000}),
            ]:
                status = mcp_call(name, args)
                log.info(f"MCP {name} -> {status}")
                time.sleep(1)
            time.sleep(4)
    except KeyboardInterrupt:
        log.info("MCPHeartbeat 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)
        release_lock(lock)

if __name__ == "__main__":
    main()
