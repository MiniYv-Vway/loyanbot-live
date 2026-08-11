#!/bin/bash
# 系统调用活跃脚本 - 定期系统调用保持系统活跃
# 策略：每4秒执行一次系统调用

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/syscall_keepalive.log"
PID_FILE="$LOG_DIR/syscall_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 系统调用活动
syscall_activity() {
    # 执行系统调用
    python3 -c "
import os
import time

# 获取系统信息
pid = os.getpid()
ppid = os.getppid()
uid = os.getuid()
gid = os.getgid()

# 获取时间
timestamp = time.time()

# 获取进程信息
status = os.getpid()

# 打印结果
print(f'PID={pid}, PPID={ppid}, UID={uid}, GID={gid}, Time={timestamp}')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "系统调用活跃脚本启动 PID=$$"

# 主循环
while true; do
    syscall_activity
    log "系统调用活动完成"
    sleep 4
done
