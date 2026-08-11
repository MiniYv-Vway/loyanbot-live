#!/bin/bash
# 网络连接保持 - 定期网络活动
LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/network_keeper.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while true; do
    # 网络探测
    curl -s -o /dev/null -w "%{http_code}" "https://www.baidu.com" 2>/dev/null || true
    curl -s -o /dev/null -w "%{http_code}" "https://www.qq.com" 2>/dev/null || true
    
    # DNS查询
    nslookup baidu.com 2>/dev/null | head -3 || true
    
    log "网络保活完成"
    sleep 120
done
