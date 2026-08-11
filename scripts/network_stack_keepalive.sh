#!/bin/bash
# 网络栈保活 - 保持网络协议栈活跃
# 策略：每3秒执行网络协议操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/network_stack_keepalive.log"
PID_FILE="$LOG_DIR/network_stack_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 网络栈活动
network_stack_activity() {
    # TCP连接测试
    python3 -c "
import socket
import threading

def test_tcp():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        sock.connect(('127.0.0.1', 65510))
        sock.send(b'ping')
        sock.recv(1024)
        sock.close()
    except:
        pass

threads = []
for i in range(2):
    t = threading.Thread(target=test_tcp)
    t.start()
    threads.append(t)
for t in threads:
    t.join(timeout=1)
" > /dev/null 2>&1
    
    # UDP测试
    python3 -c "
import socket
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(0.5)
    sock.sendto(b'ping', ('127.0.0.1', 65510))
    sock.recvfrom(1024)
    sock.close()
except:
    pass
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "网络栈保活启动 PID=$$"

while true; do
    network_stack_activity
    log "网络栈活动完成"
    sleep 3
done
