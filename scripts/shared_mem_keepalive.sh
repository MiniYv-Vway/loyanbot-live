#!/bin/bash
# 共享内存保活 - 定期共享内存操作
# 策略：每7秒执行一次共享内存操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/shared_mem_keepalive.log"
PID_FILE="$LOG_DIR/shared_mem_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 共享内存活动
shared_mem_activity() {
    python3 -c "
import multiprocessing

# 创建共享内存
shm = multiprocessing.Array('c', 1024)

# 写入数据
shm.value = b'keepalive' + b'\\x00' * 993

# 读取数据
data = shm.value.decode('utf-8', errors='ignore').strip()

print('共享内存活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "共享内存保活启动 PID=$$"

while true; do
    shared_mem_activity
    log "共享内存活动完成"
    sleep 7
done
