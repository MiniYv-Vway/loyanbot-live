#!/bin/bash
# 内核级保活 - 定期内核操作保持内核活跃
# 策略：每5秒执行一次内核相关操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/kernel_keepalive.log"
PID_FILE="$LOG_DIR/kernel_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 内核活动
kernel_activity() {
    # 读取内核参数
    cat /proc/sys/kernel/osrelease > /dev/null 2>&1
    cat /proc/sys/kernel.hostname > /dev/null 2>&1
    cat /proc/sys/kernel.version > /dev/null 2>&1
    
    # 检查内核模块
    lsmod 2>/dev/null | wc -l > /dev/null
    
    # 读取内核日志
    dmesg 2>/dev/null | tail -1 > /dev/null
}

echo $$ > "$PID_FILE"
log "内核级保活启动 PID=$$"

while true; do
    kernel_activity
    log "内核活动完成"
    sleep 5
done
