#!/bin/bash
# 系统负载模拟 - 保持CPU和内存活动
LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/load_simulator.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while true; do
    # CPU活动
    python3 -c "
import time
start = time.time()
while time.time() - start < 2:
    _ = sum(i*i for i in range(10000))
" 2>/dev/null
    
    # 内存活动
    python3 -c "
data = bytearray(1024 * 1024)  # 1MB
for i in range(10):
    data[i*1024] = i
" 2>/dev/null
    
    log "负载模拟完成"
    sleep 60
done
