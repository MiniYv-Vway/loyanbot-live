#!/bin/bash
# 信号量保活 - 定期信号量操作
# 策略：每6秒执行一次信号量操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/semaphore_keepalive.log"
PID_FILE="$LOG_DIR/semaphore_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 信号量活动
semaphore_activity() {
    python3 -c "
import multiprocessing
import time

# 创建信号量
sem = multiprocessing.Semaphore(5)

# 使用信号量
sem.acquire()
sem.release()

print('信号量活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "信号量保活启动 PID=$$"

while true; do
    semaphore_activity
    log "信号量活动完成"
    sleep 6
done
