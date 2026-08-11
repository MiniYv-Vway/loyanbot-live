#!/bin/bash
# 超频网络保活 - 每2秒执行一次
# 策略：高频网络请求，确保网络活跃

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/ultra_network_keepalive.log"
PID_FILE="$LOG_DIR/ultra_network_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 超频网络活动
ultra_network_activity() {
    # 快速ping多个地址
    ping -c 1 -W 1 8.8.8.8 2>/dev/null || true
    ping -c 1 -W 1 1.1.1.1 2>/dev/null || true
    ping -c 1 -W 1 127.0.0.1 2>/dev/null || true
    
    # 快速HTTP请求
    curl -s -o /dev/null -w "%{http_code}" "https://httpbin.org/get" 2>/dev/null || echo "0"
    curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/" 2>/dev/null || echo "0"
}

echo $$ > "$PID_FILE"
log "超频网络保活启动 PID=$$"

while true; do
    ultra_network_activity >> "$LOG_FILE" 2>&1
    sleep 2
done
