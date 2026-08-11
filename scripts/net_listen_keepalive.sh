#!/bin/bash
# 网络监听保活 - 定期端口监听
# 策略：每4秒执行一次端口监听操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/net_listen_keepalive.log"
PID_FILE="$LOG_DIR/net_listen_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 网络监听活动
net_listen_activity() {
    python3 -c "
import socket
import threading

def listen_and_accept(port):
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('127.0.0.1', port))
        server.listen(1)
        server.settimeout(0.5)
        
        try:
            conn, addr = server.accept()
            conn.send(b'accepted')
            conn.recv(1024)
            conn.close()
        except socket.timeout:
            pass
        finally:
            server.close()
    except:
        pass

# 在多个端口监听
threads = []
for port in [65510, 65511, 65512]:
    t = threading.Thread(target=listen_and_accept, args=(port,))
    t.start()
    threads.append(t)

for t in threads:
    t.join(timeout=1)

print('网络监听活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "网络监听保活启动 PID=$$"

while true; do
    net_listen_activity
    log "网络监听活动完成"
    sleep 4
done
