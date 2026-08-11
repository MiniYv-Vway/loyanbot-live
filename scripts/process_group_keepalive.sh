#!/bin/bash
# 进程组保活 - 定期进程组操作
# 策略：每5秒执行一次进程组操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/process_group_keepalive.log"
PID_FILE="$LOG_DIR/process_group_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 进程组活动
process_group_activity() {
    python3 -c "
import os
import subprocess

# 创建进程组
proc = subprocess.Popen(['echo', 'keepalive'], stdout=subprocess.PIPE)
output = proc.communicate()[0]

# 检查进程组
pgid = os.getpgid(os.getpid())

print(f'进程组活动完成 - PGID={pgid}')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "进程组保活启动 PID=$$"

while true; do
    process_group_activity
    log "进程组活动完成"
    sleep 5
done
