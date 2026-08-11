#!/bin/bash
# 网络HTTP保活 - 定期HTTP请求
# 策略：每3秒执行一次HTTP请求

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/network_http_keepalive.log"
PID_FILE="$LOG_DIR/network_http_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# HTTP活动
http_activity() {
    # 多个HTTP请求
    curl -s -o /dev/null -w "%{http_code}" "https://httpbin.org/get" 2>/dev/null || echo "0"
    curl -s -o /dev/null -w "%{http_code}" "https://httpbin.org/post" 2>/dev/null || echo "0"
    curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/rate_limit" 2>/dev/null || echo "0"
}

echo $$ > "$PID_FILE"
log "网络HTTP保活启动 PID=$$"

while true; do
    http_activity >> "$LOG_FILE" 2>&1
    log "HTTP活动完成"
    sleep 3
done
