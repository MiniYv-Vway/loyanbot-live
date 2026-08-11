#!/bin/bash
# POSIX消息队列保活 - 定期消息队列操作
# 策略：每6秒执行一次消息队列操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/posix_mq_keepalive.log"
PID_FILE="$LOG_DIR/posix_mq_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# POSIX消息队列活动
posix_mq_activity() {
    python3 -c "
import ctypes
import ctypes.util
import os

libc = ctypes.CDLL(ctypes.util.find_library('c'), use_errno=True)

# 消息队列名称
mq_name = '/loyanbot_mq_$$'

# 打开或创建消息队列
mqd = libc.mq_open(mq_name.encode(), 0o200 | 0o1000 | 0o400, 0o666, None)  # O_RDWR | O_CREAT | O_EXCL
if mqd != -1:
    # 发送消息
    msg = b'keepalive'
    libc.mq_send(mqd, msg, len(msg), 0)
    
    # 接收消息
    buf = ctypes.create_string_buffer(1024)
    prio = ctypes.c_uint()
    libc.mq_receive(mqd, buf, 1024, ctypes.addressof(prio))
    
    # 关闭消息队列
    libc.mq_close(mqd)
    
    # 删除消息队列
    libc.mq_unlink(mq_name.encode())

print('POSIX消息队列活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "POSIX消息队列保活启动 PID=$$"

while true; do
    posix_mq_activity
    log "POSIX消息队列活动完成"
    sleep 6
done
