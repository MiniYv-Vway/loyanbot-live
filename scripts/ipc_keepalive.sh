#!/bin/bash
# 进程间通信保活 - 定期IPC操作
# 策略：每5秒执行一次IPC操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/ipc_keepalive.log"
PID_FILE="$LOG_DIR/ipc_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# IPC活动
ipc_activity() {
    python3 -c "
import multiprocessing
import time

# 创建管道
parent_conn, child_conn = multiprocessing.Pipe()

# 发送数据
child_conn.send('keepalive')

# 接收数据
data = parent_conn.recv()

# 关闭连接
parent_conn.close()
child_conn.close()

print('IPC活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "进程间通信保活启动 PID=$$"

while true; do
    ipc_activity
    log "IPC活动完成"
    sleep 5
done
