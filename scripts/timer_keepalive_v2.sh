#!/bin/bash
# 定时器保活 - 定期定时器操作
# 策略：每3秒执行一次定时器操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/timer_keepalive_v2.log"
PID_FILE="$LOG_DIR/timer_keepalive_v2.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 定时器活动
timer_activity() {
    python3 -c "
import timer
import threading

# 创建定时器
t = threading.Timer(0.1, lambda: None)
t.start()
t.join()

print('定时器活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "定时器保活启动 PID=$$"

while true; do
    timer_activity
    log "定时器活动完成"
    sleep 3
done
