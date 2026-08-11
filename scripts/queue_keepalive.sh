#!/bin/bash
# 队列保活 - 定期队列操作
# 策略：每5秒执行一次队列操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/queue_keepalive.log"
PID_FILE="$LOG_DIR/queue_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 队列活动
queue_activity() {
    python3 -c "
from queue import Queue

# 创建队列
q = Queue()

# 入队和出队
q.put('keepalive')
item = q.get()
q.task_done()

print('队列活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "队列保活启动 PID=$$"

while true; do
    queue_activity
    log "队列活动完成"
    sleep 5
done
