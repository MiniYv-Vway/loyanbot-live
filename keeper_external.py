#!/usr/bin/env python3
"""外部心跳守护 v2 - 高频访问 + 多服务覆盖"""
import os, sys, time, logging, urllib.request, random
from pathlib import Path

LOG_DIR = Path("/root/loyanbot/storage/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
PID_FILE = LOG_DIR / "keeper_external.pid"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [ExternalKeeper] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "keeper_external.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("ExternalKeeper")

# 增加更多外部服务
HEARTBEAT_URLS = [
    "https://api.github.com/rate_limit",
    "https://www.google.com/favicon.ico",
    "https://www.cloudflare.com/",
    "https://aws.amazon.com/",
    "https://httpbin.org/get",
    "https://raw.githubusercontent.com/robots.txt",
]

def keepalive():
    """高频访问外部服务"""
    while True:
        for url in HEARTBEAT_URLS:
            try:
                resp = urllib.request.urlopen(url, timeout=5)
                log.info(f"心跳成功: {url} ({resp.status})")
            except Exception as e:
                log.debug(f"心跳失败 {url}: {e}")
        time.sleep(10)  # 每10秒一轮

def main():
    PID_FILE.write_text(str(os.getpid()))
    log.info("ExternalKeeper v2 启动")
    try:
        keepalive()
    except KeyboardInterrupt:
        log.info("ExternalKeeper 停止")
    finally:
        PID_FILE.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
