#!/bin/bash
# 网络套接字保活 - 定期套接字操作
# 策略：每3秒执行一次套接字操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/socket_keepalive.log"
PID_FILE="$LOG_DIR/socket_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 套接字活动
socket_activity() {
    python3 -c "
import socket
import threading

def tcp_socket():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        sock.connect(('127.0.0.1', 65510))
        sock.send(b'keepalive')
        sock.recv(1024)
        sock.close()
    except:
        pass

def udp_socket():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(0.5)
        sock.sendto(b'keepalive', ('127.0.0.1', 65510))
        sock.recvfrom(1024)
        sock.close()
    except:
        pass

threads = []
for _ in range(2):
    t = threading.Thread(target=tcp_socket)
    t.start()
    threads.append(t)
t = threading.Thread(target=udp_socket)
t.start()
threads.append(t)

for t in threads:
    t.join(timeout=1)

print('套接字活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "网络套接字保活启动 PID=$$"

while true; do
    socket_activity
    log "套接字活动完成"
    sleep 3
done
