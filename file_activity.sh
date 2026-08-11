#!/bin/bash
# 文件活动保持 - 定期文件操作
LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/file_activity.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while true; do
    # 文件读写操作
    echo "activity_$(date +%s)" > /tmp/file_test_$$
    cat /tmp/file_test_$$ > /dev/null
    rm -f /tmp/file_test_$$
    
    # 目录列表
    ls /tmp >/dev/null 2>&1
    
    log "文件活动保持完成"
    sleep 600
done
