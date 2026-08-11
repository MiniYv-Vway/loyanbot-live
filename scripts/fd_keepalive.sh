#!/bin/bash
# 文件描述符活跃脚本 - 定期文件描述符操作保持FD活跃
# 策略：每7秒执行一次文件描述符操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/fd_keepalive.log"
PID_FILE="$LOG_DIR/fd_keepalive.pid"
WORK_DIR="/tmp/loyanbot_fd"

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 文件描述符活动
fd_activity() {
    # 打开和关闭文件描述符
    python3 -c "
import os
import tempfile

# 打开多个文件描述符
fds = []
for i in range(10):
    fd, path = tempfile.mkstemp(dir='/tmp')
    fds.append(fd)

# 读写文件
for fd in fds:
    os.write(fd, b'keepalive')
    os.lseek(fd, 0, 0)
    os.read(fd, 10)

# 关闭文件描述符
for fd in fds:
    os.close(fd)

# 删除临时文件
import glob
for f in glob.glob('/tmp/tmp*'):
    os.remove(f)

print('文件描述符活动完成')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "文件描述符活跃脚本启动 PID=$$"

# 主循环
while true; do
    fd_activity
    log "文件描述符活动完成"
    sleep 7
done
