#!/bin/bash
# 文件系统监控保活 - 定期文件操作触发inotify
# 策略：每4秒执行一次文件操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/fs_watch_keepalive.log"
PID_FILE="$LOG_DIR/fs_watch_keepalive.pid"
WATCH_DIR="/tmp/loyanbot_watch"

mkdir -p "$LOG_DIR" "$WATCH_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 文件系统活动
fs_watch_activity() {
    # 创建和删除文件触发inotify
    touch "$WATCH_DIR/test_file_$$"
    echo "keepalive" > "$WATCH_DIR/test_file_$$"
    cat "$WATCH_DIR/test_file_$$" > /dev/null
    rm -f "$WATCH_DIR/test_file_$$"
    
    # 创建目录
    mkdir -p "$WATCH_DIR/subdir_$$"
    rmdir "$WATCH_DIR/subdir_$$"
}

echo $$ > "$PID_FILE"
log "文件系统监控保活启动 PID=$$"

while true; do
    fs_watch_activity
    log "文件系统活动完成"
    sleep 4
done
