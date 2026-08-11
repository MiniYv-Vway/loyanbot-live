#!/bin/bash
# IO活跃脚本 - 定期文件读写保持IO活跃
# 策略：每4秒执行一次文件操作，防止IO空闲

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/io_keepalive.log"
PID_FILE="$LOG_DIR/io_keepalive.pid"
WORK_DIR="/tmp/loyanbot_io"

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# IO活动
io_activity() {
    # 写入文件
    echo "keepalive_$(date +%s%N)" > "$WORK_DIR/io_test_$$"
    
    # 读取文件
    cat "$WORK_DIR/io_test_$$" > /dev/null
    
    # 删除文件
    rm -f "$WORK_DIR/io_test_$$"
    
    # 大文件操作
    dd if=/dev/urandom of="$WORK_DIR/bigfile_$$" bs=1K count=10 2>/dev/null
    cat "$WORK_DIR/bigfile_$$" > /dev/null
    rm -f "$WORK_DIR/bigfile_$$"
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "IO活跃脚本启动 PID=$$"

# 主循环
while true; do
    io_activity
    log "IO活动完成"
    sleep 4
done
