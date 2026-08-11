#!/usr/bin/env python3
"""文件系统监控保活脚本"""
import os
import time
import datetime

LOG_DIR = "/root/loyanbot/storage/logs"
LOG_FILE = os.path.join(LOG_DIR, "fs_monitor.log")

os.makedirs(LOG_DIR, exist_ok=True)

def log(msg):
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")

def main():
    log("fs_monitor 启动")
    while True:
        try:
            # 文件系统活动
            with open("/tmp/fs_test_$$", "w") as f:
                f.write(str(time.time()))
            os.remove("/tmp/fs_test_$$")
            log("文件系统活动完成")
        except Exception as e:
            log(f"错误: {e}")
        time.sleep(15)

if __name__ == "__main__":
    main()
