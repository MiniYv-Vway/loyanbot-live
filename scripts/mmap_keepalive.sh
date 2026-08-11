#!/bin/bash
# 内存映射保活 - 定期mmap操作
# 策略：每6秒执行一次内存映射操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/mmap_keepalive.log"
PID_FILE="$LOG_DIR/mmap_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 内存映射活动
mmap_activity() {
    python3 -c "
import mmap
import os
import tempfile

# 创建临时文件
fd, path = tempfile.mkstemp()

try:
    # 写入数据
    os.write(fd, b'keepalive' + b'\\x00' * 100)
    
    # 内存映射
    with open(fd, 'r+b') as f:
        mm = mmap.mmap(f.fileno(), 0)
        data = mm.read(100)
        mm.seek(0)
        mm.write(b'updated')
        mm.flush()
        mm.close()
finally:
    os.close(fd)
    os.remove(path)

print('内存映射活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "内存映射保活启动 PID=$$"

while true; do
    mmap_activity
    log "内存映射活动完成"
    sleep 6
done
