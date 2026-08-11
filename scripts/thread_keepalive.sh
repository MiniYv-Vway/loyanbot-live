#!/bin/bash
# 线程活跃脚本 - 定期线程操作保持多线程活跃
# 策略：每5秒执行一次线程操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/thread_keepalive.log"
PID_FILE="$LOG_DIR/thread_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 线程活动
thread_activity() {
    # 创建和管理线程
    python3 -c "
import threading
import time

def worker():
    for _ in range(10):
        time.sleep(0.1)

# 创建多个线程
threads = []
for i in range(5):
    t = threading.Thread(target=worker)
    t.start()
    threads.append(t)

# 等待线程完成
for t in threads:
    t.join()

print('线程活动完成')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "线程活跃脚本启动 PID=$$"

# 主循环
while true; do
    thread_activity
    log "线程活动完成"
    sleep 5
done
