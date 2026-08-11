#!/bin/bash
# 虚拟内存保活 - 定期虚拟内存操作
# 策略：每5秒执行一次虚拟内存操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/virtual_mem_keepalive.log"
PID_FILE="$LOG_DIR/virtual_mem_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 虚拟内存活动
virtual_mem_activity() {
    # 读取虚拟内存信息
    cat /proc/self/status 2>/dev/null | grep -E "VmSize|VmRSS|VmPeak" > /dev/null
    
    # 检查虚拟内存映射
    cat /proc/self/maps 2>/dev/null | wc -l > /dev/null
    
    # 检查内存映射
    cat /proc/self/smaps 2>/dev/null | wc -l > /dev/null
}

echo $$ > "$PID_FILE"
log "虚拟内存保活启动 PID=$$"

while true; do
    virtual_mem_activity
    log "虚拟内存活动完成"
    sleep 5
done
