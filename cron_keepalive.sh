#!/bin/bash
# 定时任务保活 - 模拟cron活动
LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/cron_keepalive.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while true; do
    # 模拟cron任务执行
    date >> /tmp/cron_test_$$ 2>/dev/null
    cat /tmp/cron_test_$$ > /dev/null 2>&1
    rm -f /tmp/cron_test_$$ 2>/dev/null
    
    # 轻量CPU活动
    python3 -c "import time; time.sleep(55)" 2>/dev/null
    
    log "cron保活周期完成"
done
