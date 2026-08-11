#!/bin/bash
# 日志活跃脚本 - 定期日志写入保持日志系统活跃
# 策略：每3秒执行一次日志写入

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/log_keepalive.log"
PID_FILE="$LOG_DIR/log_keepalive.pid"
ACTIVITY_LOG="$LOG_DIR/activity.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 日志活动
log_activity() {
    # 写入活动日志
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 活跃活动 - $(date +%s)" >> "$ACTIVITY_LOG"
    
    # 轮转日志
    local max_size=1048576  # 1MB
    local current_size=$(stat -c%s "$ACTIVITY_LOG" 2>/dev/null || echo 0)
    if [ "$current_size" -gt "$max_size" ]; then
        mv "$ACTIVITY_LOG" "$ACTIVITY_LOG.$(date +%s).bak"
        touch "$ACTIVITY_LOG"
    fi
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "日志活跃脚本启动 PID=$$"

# 主循环
while true; do
    log_activity
    log "日志活动完成"
    sleep 3
done
