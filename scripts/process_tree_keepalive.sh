#!/bin/bash
# 进程树保活 - 定期进程树操作
# 策略：每4秒执行一次进程树操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/process_tree_keepalive.log"
PID_FILE="$LOG_DIR/process_tree_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 进程树活动
process_tree_activity() {
    # 获取进程树
    ps auxf 2>/dev/null | wc -l > /dev/null
    pstree 2>/dev/null | wc -l > /dev/null
    
    # 获取进程组
    ps -o sid=,pgid=,pid= 2>/dev/null | wc -l > /dev/null
}

echo $$ > "$PID_FILE"
log "进程树保活启动 PID=$$"

while true; do
    process_tree_activity
    log "进程树活动完成"
    sleep 4
done
