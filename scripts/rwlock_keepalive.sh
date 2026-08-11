#!/bin/bash
# 读写锁保活 - 定期读写锁操作
# 策略：每5秒执行一次读写锁操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/rwlock_keepalive.log"
PID_FILE="$LOG_DIR/rwlock_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 读写锁活动
rwlock_activity() {
    python3 -c "
import threading
import time

# 创建读写锁（使用Condition模拟）
rwlock = threading.Condition()
readers = 0

def reader():
    global readers
    with rwlock:
        readers += 1
        time.sleep(0.02)
        readers -= 1

def writer():
    with rwlock:
        time.sleep(0.02)

threads = []
for _ in range(2):
    t = threading.Thread(target=reader)
    t.start()
    threads.append(t)

t = threading.Thread(target=writer)
t.start()
threads.append(t)

for t in threads:
    t.join(timeout=1)

print('读写锁活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "读写锁保活启动 PID=$$"

while true; do
    rwlock_activity
    log "读写锁活动完成"
    sleep 5
done
