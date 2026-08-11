#!/bin/bash
# 系统级保活 - 监控系统级指标
# 策略：每4秒检查系统负载，保持系统活跃

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/system_keepalive.log"
PID_FILE="$LOG_DIR/system_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 系统级活动
system_activity() {
    # 检查系统负载
    uptime > /dev/null 2>&1
    
    # 检查内存
    free -h > /dev/null 2>&1
    
    # 检查磁盘
    df -h / > /dev/null 2>&1
    
    # 检查进程数
    ps aux | wc -l > /dev/null 2>&1
    
    # 检查网络接口
    ip link show 2>/dev/null | wc -l > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "系统级保活启动 PID=$$"

while true; do
    system_activity
    log "系统活动完成"
    sleep 4
done
