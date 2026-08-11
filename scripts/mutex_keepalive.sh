#!/bin/bash
# 互斥锁保活 - 定期互斥锁操作
# 策略：每4秒执行一次互斥锁操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/mutex_keepalive.log"
PID_FILE="$LOG_DIR/mutex_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 互斥锁活动
mutex_activity() {
    python3 -c "
import threading
import time

# 创建锁
lock = threading.Lock()

def locked_work():
    with lock:
        time.sleep(0.05)

threads = []
for _ in range(3):
    t = threading.Thread(target=locked_work)
    t.start()
    threads.append(t)

for t in threads:
    t.join(timeout=1)

print('互斥锁活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "互斥锁保活启动 PID=$$"

while true; do
    mutex_activity
    log "互斥锁活动完成"
    sleep 4
done
