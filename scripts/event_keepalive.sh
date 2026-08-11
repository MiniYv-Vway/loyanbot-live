#!/bin/bash
# 事件保活 - 定期事件操作
# 策略：每4秒执行一次事件操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/event_keepalive.log"
PID_FILE="$LOG_DIR/event_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 事件活动
event_activity() {
    python3 -c "
import threading

# 创建事件
event = threading.Event()

# 设置和清除事件
event.set()
event.clear()
event.wait(timeout=0.1)

print('事件活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "事件保活启动 PID=$$"

while true; do
    event_activity
    log "事件活动完成"
    sleep 4
done
