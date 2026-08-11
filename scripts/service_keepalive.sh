#!/bin/bash
# 系统服务活跃脚本 - 定期系统服务检测保持服务活跃
# 策略：每15秒执行一次系统服务检测

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/service_keepalive.log"
PID_FILE="$LOG_DIR/service_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 系统服务活动
service_activity() {
    # 检查系统服务状态
    systemctl list-units --type=service --state=running 2>/dev/null | wc -l > /dev/null
    
    # 检查服务列表
    service --status-all 2>/dev/null | wc -l > /dev/null
    
    # 检查进程状态
    ps aux 2>/dev/null | wc -l > /dev/null
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "系统服务活跃脚本启动 PID=$$"

# 主循环
while true; do
    service_activity
    log "系统服务活动完成"
    sleep 15
done
