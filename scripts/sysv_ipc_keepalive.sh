#!/bin/bash
# 系统V IPC保活 - 定期System V IPC操作
# 策略：每7秒执行一次System V IPC操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/sysv_ipc_keepalive.log"
PID_FILE="$LOG_DIR/sysv_ipc_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# System V IPC活动
sysv_ipc_activity() {
    python3 -c "
import ctypes
import ctypes.util
import os
import tempfile

# 加载libc
libc = ctypes.CDLL(ctypes.util.find_library('c'), use_errno=True)

# 创建共享内存
shm_path = '/loyanbot_shm_$$'
fd = libc.open(shm_path.encode(), 0o666 | 64, 0o666)  # O_CREAT | O_RDWR
if fd >= 0:
    libc.ftruncate(fd, 1024)
    
    # 映射共享内存
    ptr = libc.mmap(None, 1024, 1 | 2, 1, fd, 0)  # PROT_READ | PROT_WRITE, MAP_SHARED
    if ptr != -1:
        # 写入数据
        ctypes.memset(ptr, ord('k'), 100)
        # 卸载映射
        libc.munmap(ptr, 1024)
    
    libc.close(fd)
    libc.unlink(shm_path.encode())

print('System V IPC活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "系统V IPC保活启动 PID=$$"

while true; do
    sysv_ipc_activity
    log "System V IPC活动完成"
    sleep 7
done
