#!/bin/bash
# 多重备份保活 - 三层备份机制
# 策略：同时运行三个不同机制的保活，确保至少有一个存活

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/multi_backup_keepalive.log"
PID_FILE="$LOG_DIR/multi_backup_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 第一层：快速心跳（每1秒）
layer1_heartbeat() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] L1心跳" >> "$LOG_DIR/l1_heartbeat.log"
}

# 第二层：中等心跳（每5秒）
layer2_heartbeat() {
    # 执行一些系统调用
    ps aux > /dev/null 2>&1
    df -h > /dev/null 2>&1
    free -h > /dev/null 2>&1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] L2心跳" >> "$LOG_DIR/l2_heartbeat.log"
}

# 第三层：慢速心跳（每30秒）
layer3_heartbeat() {
    # 执行网络请求
    curl -s -o /dev/null "https://httpbin.org/get" 2>/dev/null || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] L3心跳" >> "$LOG_DIR/l3_heartbeat.log"
}

echo $$ > "$PID_FILE"
log "多重备份保活启动 PID=$$"

# 启动第一层
(
    while true; do
        layer1_heartbeat
        sleep 1
    done
) &
L1_PID=$!

# 启动第二层
(
    while true; do
        layer2_heartbeat
        sleep 5
    done
) &
L2_PID=$!

# 启动第三层
(
    while true; do
        layer3_heartbeat
        sleep 30
    done
) &
L3_PID=$!

# 主进程等待
wait $L1_PID $L2_PID $L3_PID
