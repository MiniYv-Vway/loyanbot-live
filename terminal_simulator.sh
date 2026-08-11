#!/bin/bash
# 终端活动模拟 - 保持终端活跃
LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/terminal_simulator.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while true; do
    # 模拟终端命令
    echo "keepalive_$(date +%s)" > /tmp/terminal_test_$$
    cat /tmp/terminal_test_$$ | wc -c > /dev/null
    rm -f /tmp/terminal_test_$$
    
    # 终端状态检查
    tty >/dev/null 2>&1 || true
    
    log "终端活动模拟完成"
    sleep 300
done
