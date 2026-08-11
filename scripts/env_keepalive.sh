#!/bin/bash
# 环境变量活跃脚本 - 定期环境变量操作保持环境活跃
# 策略：每10秒执行一次环境变量操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/env_keepalive.log"
PID_FILE="$LOG_DIR/env_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 环境变量活动
env_activity() {
    # 读取和设置环境变量
    python3 -c "
import os

# 读取环境变量
env_vars = os.environ.copy()

# 设置临时环境变量
os.environ['LOYANBOT_KEEPALIVE'] = 'active'
os.environ['KEEPALIVE_TIMESTAMP'] = str(int(__import__('time').time()))

# 获取环境变量
pid = os.environ.get('PID', 'unknown')
user = os.environ.get('USER', 'unknown')

# 删除临时环境变量
del os.environ['LOYANBOT_KEEPALIVE']
del os.environ['KEEPALIVE_TIMESTAMP']

print(f'环境变量活动完成 - PID={pid}, User={user}')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "环境变量活跃脚本启动 PID=$$"

# 主循环
while true; do
    env_activity
    log "环境变量活动完成"
    sleep 10
done
