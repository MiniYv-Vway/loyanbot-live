#!/bin/bash
# 网络DNS保活 - 定期DNS查询
# 策略：每4秒执行一次DNS查询

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/network_dns_keepalive.log"
PID_FILE="$LOG_DIR/network_dns_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# DNS活动
dns_activity() {
    # 查询多个域名
    nslookup github.com 2>/dev/null | head -2 || true
    nslookup google.com 2>/dev/null | head -2 || true
    nslookup cloudflare.com 2>/dev/null | head -2 || true
    nslookup api.github.com 2>/dev/null | head -2 || true
}

echo $$ > "$PID_FILE"
log "网络DNS保活启动 PID=$$"

while true; do
    dns_activity
    log "DNS活动完成"
    sleep 4
done
