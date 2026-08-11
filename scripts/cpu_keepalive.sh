#!/bin/bash
# CPU活跃脚本 - 周期性计算任务保持CPU活跃
# 策略：每3秒执行一次计算任务，防止CPU空闲

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/cpu_keepalive.log"
PID_FILE="$LOG_DIR/cpu_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# CPU活动
cpu_activity() {
    # 数学计算
    python3 -c "
import math
result = sum(math.sqrt(i) for i in range(1000))
print(result)
" > /dev/null 2>&1
    
    # 字符串处理
    python3 -c "
s = 'keepalive' * 1000
result = s[::-1]
print(len(result))
" > /dev/null 2>&1
    
    # 矩阵计算
    python3 -c "
import random
matrix = [[random.random() for _ in range(10)] for _ in range(10)]
result = sum(sum(row) for row in matrix)
print(result)
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "CPU活跃脚本启动 PID=$$"

# 主循环
while true; do
    cpu_activity
    log "CPU活动完成"
    sleep 3
done
