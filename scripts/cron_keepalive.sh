#!/bin/bash
# 定时任务活跃脚本 - 定期执行定时任务保持cron活跃
# 策略：每分钟执行一次定时任务

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/cron_keepalive.log"
PID_FILE="$LOG_DIR/cron_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 定时任务活动
cron_activity() {
    # 执行一个简单的定时任务
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 定时任务活动" >> "$LOG_DIR/cron_activity.log"
    
    # 更新计数
    local count_file="$LOG_DIR/cron_count.txt"
    if [ -f "$count_file" ]; then
        count=$(cat "$count_file")
        echo $((count + 1)) > "$count_file"
    else
        echo "1" > "$count_file"
    fi
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "定时任务活跃脚本启动 PID=$$"

# 主循环
while true; do
    cron_activity
    log "定时任务活动完成"
    sleep 60
done
