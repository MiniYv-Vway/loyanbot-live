#!/bin/bash
# 管道保活 - 定期管道操作
# 策略：每4秒执行一次管道操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/pipe_keepalive.log"
PID_FILE="$LOG_DIR/pipe_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 管道活动
pipe_activity() {
    # 创建管道并读写
    python3 -c "
import os
import threading

# 创建管道
read_fd, write_fd = os.pipe()

# 写入数据
os.write(write_fd, b'keepalive')

# 读取数据
data = os.read(read_fd, 1024)

# 关闭管道
os.close(read_fd)
os.close(write_fd)

print('管道活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "管道保活启动 PID=$$"

while true; do
    pipe_activity
    log "管道活动完成"
    sleep 4
done
