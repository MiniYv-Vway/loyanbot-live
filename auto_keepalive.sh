#!/bin/bash
# 自动保活脚本 - 无需对话也能防止VM休眠
# 策略：定期执行多种活动，模拟系统活跃状态

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/auto_keepalive.log"
PID_FILE="$LOG_DIR/auto_keepalive.pid"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 1. 外部网络活动（每15秒）
external_ping() {
    curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/rate_limit" 2>/dev/null || echo "0"
    curl -s -o /dev/null -w "%{http_code}" "https://www.google.com/favicon.ico" 2>/dev/null || echo "0"
    curl -s -o /dev/null -w "%{http_code}" "https://www.cloudflare.com/" 2>/dev/null || echo "0"
}

# 2. 系统活动（每15秒）
system_activity() {
    # CPU活动
    python3 -c "print(sum(i*i for i in range(1000)))" > /dev/null 2>&1
    # IO活动
    echo "keepalive" > /tmp/keepalive_$$
    cat /tmp/keepalive_$$ > /dev/null
    rm -f /tmp/keepalive_$$
    # DNS活动
    nslookup localhost 2>/dev/null | head -3 || true
}

# 3. 平台API活动（每60秒）
platform_activity() {
    curl -s -X POST "http://127.0.0.1:65510/mcp" \
        -H "Authorization: Bearer agent_access_930591ae-b8ee-4b2f-b5ad-1779f2d98207" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' 2>/dev/null || true
}

# 4. Git活动（每300秒）
git_activity() {
    cd /workspace && git status 2>/dev/null || true
    cd /root/loyanbot && git status 2>/dev/null || true
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "自动保活脚本启动 PID=$$"

# 主循环
while true; do
    external_ping
    system_activity
    log "15秒活动完成"
    sleep 15
    
    platform_activity
    log "60秒平台活动完成"
    sleep 45
    
    git_activity
    log "300秒git活动完成"
    sleep 240
done
