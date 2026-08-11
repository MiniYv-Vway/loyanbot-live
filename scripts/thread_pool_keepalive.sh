#!/bin/bash
# 线程池保活 - 定期线程池操作
# 策略：每6秒执行一次线程池操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/thread_pool_keepalive.log"
PID_FILE="$LOG_DIR/thread_pool_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 线程池活动
thread_pool_activity() {
    python3 -c "
from concurrent.futures import ThreadPoolExecutor
import time

def worker(x):
    return x * x

# 创建线程池
with ThreadPoolExecutor(max_workers=3) as executor:
    results = list(executor.map(worker, [1, 2, 3]))

print('线程池活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "线程池保活启动 PID=$$"

while true; do
    thread_pool_activity
    log "线程池活动完成"
    sleep 6
done
