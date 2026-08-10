#!/usr/bin/env python3
"""系统活动守护 v2 - CPU/IO/DNS/进程活动"""
import os, sys, time, logging, hashlib, socket
from pathlib import Path

LOG_DIR = Path("/root/loyanbot/storage/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
PID_FILE = LOG_DIR / "keeper_system.pid"
TEMP_DIR = Path("/tmp/loyanbot_keepalive")
TEMP_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [SystemKeeper] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "keeper_system.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("SystemKeeper")

def cpu_activity():
    """微量CPU活动"""
    _ = sum(i*i for i in range(10000))
    _ = hashlib.sha256(str(time.time()).encode()).hexdigest()

def io_activity():
    """磁盘IO活动"""
    try:
        p = TEMP_DIR / f"keepalive_{int(time.time())}"
        p.write_bytes(os.urandom(1024))
        p.read_bytes()
        p.unlink(missing_ok=True)
    except:
        pass

def dns_activity():
    """DNS查询活动"""
    try:
        socket.getaddrinfo('localhost', 80, socket.AF_INET, socket.SOCK_STREAM)
    except:
        pass

def proc_activity():
    """进程状态读取"""
    try:
        with open("/proc/stat") as f:
            f.read(512)
        with open("/proc/meminfo") as f:
            f.read(512)
        with open("/proc/loadavg") as f:
            f.read(128)
    except:
        pass

def main():
    PID_FILE.write_text(str(os.getpid()))
    log.info("SystemKeeper v2 启动")
    try:
        while True:
            cpu_activity()
            io_activity()
            dns_activity()
            proc_activity()
            log.debug("系统活动完成")
            time.sleep(8)  # 每8秒一轮
    except KeyboardInterrupt:
        log.info("SystemKeeper 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
