#!/usr/bin/env python3
"""全能守护者 - 监控并重启所有保活进程"""
import os, sys, time, signal, subprocess, logging, urllib.request, json
from pathlib import Path

BASE = Path("/root/loyanbot")
WORKSPACE = Path("/workspace")
LOG_DIR = BASE / "storage" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [Supervisor] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "supervisor.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("Supervisor")

PROCESSES = {
    "http_server": {
        "script": str(WORKSPACE / "http_server.py"),
        "pid_file": LOG_DIR / "http_server.pid",
        "required": True,
    },
    "keeper_external": {
        "script": str(BASE / "keeper_external.py"),
        "pid_file": LOG_DIR / "keeper_external.pid",
        "required": True,
    },
    "keeper_system": {
        "script": str(BASE / "keeper_system.py"),
        "pid_file": LOG_DIR / "keeper_system.pid",
        "required": True,
    },
    "keeper_platform": {
        "script": str(BASE / "keeper_platform.py"),
        "pid_file": LOG_DIR / "keeper_platform.pid",
        "required": True,
    },
    "keeper_terminal": {
        "script": str(BASE / "keeper_terminal.py"),
        "pid_file": LOG_DIR / "keeper_terminal.pid",
        "required": True,
    },
}

KEEPALIVE_URLS = [
    "http://127.0.0.1:5090/",
    "http://127.0.0.1:8000/",
    "https://api.github.com/rate_limit",
    "https://www.google.com/favicon.ico",
    "https://www.cloudflare.com/",
    "https://aws.amazon.com/",
    "https://monkeycode-ai.com/",
    "http://127.0.0.1:65510/health",
]

def is_alive(pid):
    try:
        os.kill(pid, 0)
        with open(f"/proc/{pid}/stat") as f:
            return f.read().split()[2] != "Z"
    except (ProcessLookupError, FileNotFoundError):
        return False

def get_pid(pid_file):
    if pid_file.exists():
        try:
            return int(pid_file.read_text().strip())
        except:
            pass
    return None

def ensure_process(name, cfg):
    pid = get_pid(cfg["pid_file"])
    if pid and is_alive(pid):
        return

    if pid:
        log.info(f"{name} (PID={pid}) 已死亡，重启...")
        cfg["pid_file"].unlink(missing_ok=True)

    log.info(f"启动 {name}...")
    try:
        kwargs = {
            "stdout": open(LOG_DIR / f"{name}.log", "a", buffering=1),
            "stderr": subprocess.STDOUT,
            "start_new_session": True,
        }
        if "env" in cfg:
            env = os.environ.copy()
            env.update(cfg["env"])
            kwargs["env"] = env

        proc = subprocess.Popen([sys.executable, cfg["script"]], cwd=str(BASE), **kwargs)
        cfg["pid_file"].write_text(str(proc.pid))
        log.info(f"{name} 已启动 PID={proc.pid}")
    except Exception as e:
        log.error(f"启动 {name} 失败: {e}")

def keepalive_ping():
    for url in KEEPALIVE_URLS:
        try:
            resp = urllib.request.urlopen(url, timeout=5)
            log.debug(f"ping OK: {url} ({resp.status})")
        except Exception:
            pass
    # 微量 CPU 活动
    _ = sum(i*i for i in range(5000))
    _ = hashlib_sha = __import__('hashlib').sha256(str(time.time()).encode()).hexdigest()
    # 微量 IO
    try:
        p = LOG_DIR / f".ping_{int(time.time())}"
        p.write_bytes(os.urandom(512))
        p.read_bytes()
        p.unlink(missing_ok=True)
    except:
        pass

import hashlib

def main():
    log.info("=== Supervisor v1.1 启动 ===")
    log.info(f"BASE={BASE}")
    log.info(f"WORKSPACE={WORKSPACE}")

    # 清理僵尸 PID 文件
    for cfg in PROCESSES.values():
        pid = get_pid(cfg["pid_file"])
        if pid and not is_alive(pid):
            log.info(f"清理僵尸 PID 文件: {cfg['pid_file'].name} (PID={pid})")
            cfg["pid_file"].unlink(missing_ok=True)

    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))

    # 初始启动所有进程
    for name, cfg in PROCESSES.items():
        ensure_process(name, cfg)

    cycle = 0
    while True:
        time.sleep(20)
        cycle += 1
        log.info(f"检查周期 #{cycle}")
        for name, cfg in PROCESSES.items():
            ensure_process(name, cfg)
        keepalive_ping()

if __name__ == "__main__":
    main()
