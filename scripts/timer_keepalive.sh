#!/bin/bash
# 定时任务活跃脚本 - 定期执行定时任务保持系统活跃
# 策略：每分钟执行一次定时任务

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/timer_keepalive.log"
PID_FILE="$LOG_DIR/timer_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 定时活动
timer_activity() {
    # 执行一个简单的定时任务
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 定时活动" >> "$LOG_DIR/timer_log.txt"
    
    # 更新一个计数文件
    if [ -f "$LOG_DIR/timer_count.txt" ]; then
        count=$(cat "$LOG_DIR/timer_count.txt")
        echo $((count + 1)) > "$LOG_DIR/timer_count.txt"
    else
        echo "1" > "$LOG_DIR/timer_count.txt"
    fi
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "定时任务活跃脚本启动 PID=$$"

# 主循环
while true; do
    timer_activity
    log "定时活动完成"
    sleep 60
done
