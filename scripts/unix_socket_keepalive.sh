#!/bin/bash
# Unix域套接字保活 - 定期本地套接字操作
# 策略：每5秒执行一次Unix域套接字操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/unix_socket_keepalive.log"
PID_FILE="$LOG_DIR/unix_socket_keepalive.pid"
SOCKET_DIR="/tmp/loyanbot_sockets"

mkdir -p "$LOG_DIR" "$SOCKET_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Unix域套接字活动
unix_socket_activity() {
    python3 -c "
import socket
import os
import tempfile

# 创建临时套接字路径
sock_path = '/tmp/loyanbot_unix_$$'

# 删除旧套接字
if os.path.exists(sock_path):
    os.remove(sock_path)

try:
    # 创建Unix域套接字
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(sock_path)
    server.listen(1)
    server.settimeout(0.5)
    
    # 客户端连接
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(sock_path)
    
    # 服务端接受
    conn, addr = server.accept()
    
    # 数据传输
    conn.send(b'keepalive')
    data = client.recv(1024)
    
    # 关闭连接
    conn.close()
    client.close()
    server.close()
finally:
    if os.path.exists(sock_path):
        os.remove(sock_path)

print('Unix域套接字活动完成')
" > /dev/null 2>&1
}

echo $$ > "$PID_FILE"
log "Unix域套接字保活启动 PID=$$"

while true; do
    unix_socket_activity
    log "Unix域套接字活动完成"
    sleep 5
done
