#!/bin/bash
# API活跃脚本 - 定期API请求保持API活跃
# 策略：每8秒执行一次API请求

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/api_keepalive.log"
PID_FILE="$LOG_DIR/api_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# API活动
api_activity() {
    # 本地API
    curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:65510/mcp" 2>/dev/null || echo "0"
    
    # GitHub API
    curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/" 2>/dev/null || echo "0"
    
    # JSONPlaceholder API
    curl -s -o /dev/null -w "%{http_code}" "https://jsonplaceholder.typicode.com/posts/1" 2>/dev/null || echo "0"
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "API活跃脚本启动 PID=$$"

# 主循环
while true; do
    api_activity >> "$LOG_FILE" 2>&1
    log "API活动完成"
    sleep 8
done
