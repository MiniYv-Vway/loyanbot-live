#!/bin/bash
# 异步通知保活 - 定期fcntl异步操作
# 策略：每5秒执行一次异步通知操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/async_notify_keepalive.log"
PID_FILE="$LOG_DIR/async_notify_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 异步通知活动
async_notify_activity() {
    python3 -c "
import fcntl
import os
import tempfile

# 创建临时文件
fd, path = tempfile.mkstemp()

try:
    # 设置异步通知
    flags = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_ASYNC)
    
    # 写入数据
    os.write(fd, b'keepalive')
    
    # 清除异步通知
    fcntl.fcntl(fd, fcntl.F_SETFL, flags)
finally:
    os.close(fd)
    os.remove(path)

print('异步通知活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "异步通知保活启动 PID=$$"

while true; do
    async_notify_activity
    log "异步通知活动完成"
    sleep 5
done
