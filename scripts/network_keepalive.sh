#!/bin/bash
# 网络活跃脚本 - 定期HTTPS请求保持网络连接活跃
# 策略：每5秒执行一次网络请求，防止网络超时

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/network_keepalive.log"
PID_FILE="$LOG_DIR/network_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 网络活动
network_activity() {
    # GitHub API
    curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/rate_limit" 2>/dev/null || echo "0"
    
    # Cloudflare
    curl -s -o /dev/null -w "%{http_code}" "https://www.cloudflare.com/" 2>/dev/null || echo "0"
    
    # Google
    curl -s -o /dev/null -w "%{http_code}" "https://www.google.com/favicon.ico" 2>/dev/null || echo "0"
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "网络活跃脚本启动 PID=$$"

# 主循环
while true; do
    network_activity >> "$LOG_FILE" 2>&1
    log "网络活动完成"
    sleep 5
done
