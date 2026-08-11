#!/bin/bash
# 进程活跃脚本 - 定期进程检测保持进程表活跃
# 策略：每6秒执行一次进程检测

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/process_keepalive.log"
PID_FILE="$LOG_DIR/process_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 进程活动
process_activity() {
    # 检测进程
    ps aux | wc -l > /dev/null
    ps aux | grep -c "keepalive" > /dev/null
    
    # 检测网络进程
    netstat -tlnp 2>/dev/null | wc -l > /dev/null
    ss -tlnp 2>/dev/null | wc -l > /dev/null
    
    # 检测文件描述符
    ls /proc/self/fd 2>/dev/null | wc -l > /dev/null
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "进程活跃脚本启动 PID=$$"

# 主循环
while true; do
    process_activity
    log "进程活动完成"
    sleep 6
done
