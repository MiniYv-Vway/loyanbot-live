#!/bin/bash
# 网络协议活跃脚本 - 定期网络协议操作保持网络协议栈活跃
# 策略：每6秒执行一次网络协议操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/protocol_keepalive.log"
PID_FILE="$LOG_DIR/protocol_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 网络协议活动
protocol_activity() {
    # TCP连接测试
    python3 -c "
import socket
import threading

def tcp_test():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        sock.connect(('127.0.0.1', 65510))
        sock.send(b'keepalive')
        data = sock.recv(1024)
        sock.close()
    except:
        pass

# 创建多个TCP连接
threads = []
for i in range(3):
    t = threading.Thread(target=tcp_test)
    t.start()
    threads.append(t)

for t in threads:
    t.join(timeout=2)

print('TCP协议活动完成')
" > /dev/null 2>&1
    
    # UDP数据报测试
    python3 -c "
import socket

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(1)
    sock.sendto(b'keepalive', ('127.0.0.1', 65510))
    data, addr = sock.recvfrom(1024)
    sock.close()
except:
    pass

print('UDP协议活动完成')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "网络协议活跃脚本启动 PID=$$"

# 主循环
while true; do
    protocol_activity
    log "网络协议活动完成"
    sleep 6
done
