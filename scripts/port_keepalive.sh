#!/bin/bash
# 端口活跃脚本 - 定期端口检测保持网络端口活跃
# 策略：每5秒执行一次端口检测

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/port_keepalive.log"
PID_FILE="$LOG_DIR/port_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 端口活动
port_activity() {
    # 检测监听端口
    ss -tlnp 2>/dev/null | wc -l > /dev/null
    netstat -tlnp 2>/dev/null | wc -l > /dev/null
    
    # 检测连接端口
    ss -tnp 2>/dev/null | wc -l > /dev/null
    netstat -tnp 2>/dev/null | wc -l > /dev/null
    
    # 检测UDP端口
    ss -ulnp 2>/dev/null | wc -l > /dev/null
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "端口活跃脚本启动 PID=$$"

# 主循环
while true; do
    port_activity
    log "端口活动完成"
    sleep 5
done
