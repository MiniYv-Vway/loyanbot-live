#!/bin/bash
# 文件锁保活 - 定期文件锁操作
# 策略：每5秒执行一次文件锁操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/file_lock_keepalive.log"
PID_FILE="$LOG_DIR/file_lock_keepalive.pid"
WORK_DIR="/tmp/loyanbot_lock"

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 文件锁活动
file_lock_activity() {
    python3 -c "
import fcntl
import os
import tempfile

# 创建临时文件
fd, path = tempfile.mkstemp(dir='/tmp')

# 获取锁
with open(fd, 'w') as f:
    fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    f.write(b'keepalive')
    f.flush()
    fcntl.flock(f, fcntl.LOCK_UN)

# 释放锁
os.close(fd)
os.remove(path)

print('文件锁活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "文件锁保活启动 PID=$$"

while true; do
    file_lock_activity
    log "文件锁活动完成"
    sleep 5
done
