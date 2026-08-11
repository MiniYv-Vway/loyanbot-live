#!/bin/bash
# 信号活跃脚本 - 定期信号发送保持进程间通信活跃
# 策略：每6秒执行一次信号操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/signal_keepalive.log"
PID_FILE="$LOG_DIR/signal_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 信号活动
signal_activity() {
    # 获取当前进程ID
    local pid=$$
    
    # 发送信号到自身（无害的信号）
    kill -0 $pid 2>/dev/null
    
    # 检测其他保活进程的信号
    pids=$(pgrep -f "keepalive" 2>/dev/null)
    for p in $pids; do
        kill -0 $p 2>/dev/null
    done
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "信号活跃脚本启动 PID=$$"

# 主循环
while true; do
    signal_activity
    log "信号活动完成"
    sleep 6
done
