#!/bin/bash
# 磁盘活跃脚本 - 定期磁盘操作保持磁盘活跃
# 策略：每8秒执行一次磁盘操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/disk_keepalive.log"
PID_FILE="$LOG_DIR/disk_keepalive.pid"
WORK_DIR="/tmp/loyanbot_disk"

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 磁盘活动
disk_activity() {
    # 创建临时文件
    dd if=/dev/urandom of="$WORK_DIR/disk_test_$$" bs=1M count=5 2>/dev/null
    
    # 读取文件
    cat "$WORK_DIR/disk_test_$$" > /dev/null
    
    # 压缩文件
    tar czf "$WORK_DIR/disk_compressed_$$" -C "$WORK_DIR" disk_test_$$ 2>/dev/null
    
    # 解压文件
    tar xzf "$WORK_DIR/disk_compressed_$$" -C "$WORK_DIR" 2>/dev/null
    
    # 删除文件
    rm -f "$WORK_DIR/disk_test_$$" "$WORK_DIR/disk_compressed_$$"
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "磁盘活跃脚本启动 PID=$$"

# 主循环
while true; do
    disk_activity
    log "磁盘活动完成"
    sleep 8
done
