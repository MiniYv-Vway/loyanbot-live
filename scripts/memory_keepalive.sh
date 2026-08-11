#!/bin/bash
# 内存活跃脚本 - 定期内存操作保持内存活跃
# 策略：每7秒执行一次内存操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/memory_keepalive.log"
PID_FILE="$LOG_DIR/memory_keepalive.pid"
WORK_DIR="/tmp/loyanbot_memory"

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 内存活动
memory_activity() {
    # 内存分配和释放
    python3 -c "
import os
# 分配内存
data = bytearray(1024 * 1024)  # 1MB
# 写入数据
for i in range(len(data)):
    data[i] = i % 256
# 读取数据
sum_val = sum(data)
# 释放内存
del data
print(sum_val)
" > /dev/null 2>&1
    
    # 内存映射文件
    dd if=/dev/urandom of="$WORK_DIR/memmap_$$" bs=1M count=1 2>/dev/null
    cat "$WORK_DIR/memmap_$$" > /dev/null
    rm -f "$WORK_DIR/memmap_$$"
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "内存活跃脚本启动 PID=$$"

# 主循环
while true; do
    memory_activity
    log "内存活动完成"
    sleep 7
done
