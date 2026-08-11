#!/bin/bash
# 超频CPU保活 - 每1秒执行一次
# 策略：高频计算任务，确保CPU活跃

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/ultra_cpu_keepalive.log"
PID_FILE="$LOG_DIR/ultra_cpu_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 超频CPU活动
ultra_cpu_activity() {
    # 快速数学计算
    python3 -c "
import math
result = sum(math.sqrt(i) for i in range(500))
print(result)
" > /dev/null 2>&1
    
    # 字符串处理
    python3 -c "
s = 'keepalive' * 500
result = s[::-1]
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "超频CPU保活启动 PID=$$"

while true; do
    ultra_cpu_activity
    log "超频CPU活动完成"
    sleep 1
done
