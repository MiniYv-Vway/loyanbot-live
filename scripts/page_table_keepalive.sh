#!/bin/bash
# 页表操作保活 - 定期页表检查
# 策略：每6秒执行一次页表相关操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/page_table_keepalive.log"
PID_FILE="$LOG_DIR/page_table_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 页表活动
page_table_activity() {
    # 读取页表信息
    cat /proc/self/pagemap 2>/dev/null | wc -l > /dev/null
    cat /proc/self/stat 2>/dev/null | awk '{print $2}' > /dev/null
}

echo $$ > "$PID_FILE"
log "页表操作保活启动 PID=$$"

while true; do
    page_table_activity
    log "页表活动完成"
    sleep 6
done
