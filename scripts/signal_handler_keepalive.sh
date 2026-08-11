#!/bin/bash
# 信号处理保活 - 定期信号发送接收
# 策略：每6秒执行一次信号操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/signal_handler_keepalive.log"
PID_FILE="$LOG_DIR/signal_handler_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 信号活动
signal_activity() {
    python3 -c "
import os
import signal
import time

# 发送信号到自身
pid = os.getpid()
os.kill(pid, signal.SIGUSR1)
os.kill(pid, signal.SIGUSR2)

# 检查进程状态
status = os.waitpid(-1, os.WNOHANG)

print('信号活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "信号处理保活启动 PID=$$"

while true; do
    signal_activity
    log "信号活动完成"
    sleep 6
done
