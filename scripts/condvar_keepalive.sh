#!/bin/bash
# 条件变量保活 - 定期条件变量操作
# 策略：每5秒执行一次条件变量操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/condvar_keepalive.log"
PID_FILE="$LOG_DIR/condvar_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 条件变量活动
condvar_activity() {
    python3 -c "
import threading
import time

# 创建条件和锁
condition = threading.Condition()
flag = False

def waiter():
    with condition:
        condition.wait(timeout=0.1)

def notifier():
    time.sleep(0.05)
    with condition:
        condition.notify()

threads = []
for _ in range(2):
    t = threading.Thread(target=waiter)
    t.start()
    threads.append(t)

t = threading.Thread(target=notifier)
t.start()
threads.append(t)

for t in threads:
    t.join(timeout=1)

print('条件变量活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "条件变量保活启动 PID=$$"

while true; do
    condvar_activity
    log "条件变量活动完成"
    sleep 5
done
