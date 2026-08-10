#!/bin/bash
# MonkeyCode 服务器停止脚本

echo "=== MonkeyCode 保活系统停止 ==="

# 停止 supervisor（会级联停止所有子进程）
if pgrep -f "supervisor.py" > /dev/null; then
    echo "[INFO] 停止 Supervisor..."
    pkill -f "supervisor.py"
    sleep 2
fi

# 停止所有 keeper 进程
for keeper in keeper_platform keeper_terminal keeper_external keeper_system; do
    if pgrep -f "$keeper.py" > /dev/null; then
        echo "[INFO] 停止 $keeper..."
        pkill -f "$keeper.py"
    fi
done

# 停止 bot
if pgrep -f "bot.py" > /dev/null; then
    echo "[INFO] 停止 Bot..."
    pkill -f "bot.py"
fi

# 停止 http_server
if pgrep -f "http_server.py" > /dev/null; then
    echo "[INFO] 停止 HTTP Server..."
    pkill -f "http_server.py"
fi

sleep 1

echo ""
echo "=== 停止状态 ==="
ps aux | grep -E "(supervisor|keeper|bot|http_server)" | grep -v grep || echo "所有进程已停止"
echo ""
echo "=== 停止完成 ==="
