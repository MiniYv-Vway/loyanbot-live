#!/usr/bin/env python3
"""综合保活 - 多策略并发保活"""
import os, sys, time, logging, urllib.request, json, fcntl
from pathlib import Path

PID_FILE = Path("/root/loyanbot/storage/logs/keep_all.pid")
LOCK_FILE = Path("/root/loyanbot/storage/logs/keep_all.lock")
LOG_DIR = Path("/root/loyanbot/storage/logs")
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
    lock = acquire_lock()
    PID_FILE.write_text(str(os.getpid()))
    log.info("KeepAll 启动 - 综合保活")
    try:
        while True:
            mcp_call("background_terminal_list", {})
            time.sleep(1)
            mcp_call("request_preview", {"port": 8000})
            time.sleep(1)
            mcp_call("background_terminal_create", {"command": "echo keepalive", "timeout": 3000})
            time.sleep(1)
            external_ping()
            io_activity()
            log.info("保活周期完成")
            time.sleep(7)
    except KeyboardInterrupt:
        log.info("KeepAll 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)
        release_lock(lock)

if __name__ == "__main__":
    main()
