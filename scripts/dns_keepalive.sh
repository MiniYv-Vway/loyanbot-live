#!/bin/bash
# DNS活跃脚本 - 定期DNS查询保持DNS缓存活跃
# 策略：每10秒执行一次DNS查询

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/dns_keepalive.log"
PID_FILE="$LOG_DIR/dns_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# DNS活动
dns_activity() {
    # 查询多个域名
    nslookup github.com 2>/dev/null | head -3 || true
    nslookup google.com 2>/dev/null | head -3 || true
    nslookup cloudflare.com 2>/dev/null | head -3 || true
    nslookup api.github.com 2>/dev/null | head -3 || true
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "DNS活跃脚本启动 PID=$$"

# 主循环
while true; do
    dns_activity
    log "DNS活动完成"
    sleep 10
done
