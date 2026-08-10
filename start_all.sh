#!/bin/bash
# MonkeyCode 服务器启动脚本
# 自动启动所有保活进程

set -e

LOG_DIR="/root/loyanbot/storage/logs"
mkdir -p "$LOG_DIR"

echo "=== MonkeyCode 保活系统启动 ==="
echo "时间: $(date)"
echo "日志目录: $LOG_DIR"

# 检查 supervisor 是否已在运行
if pgrep -f "supervisor.py" > /dev/null; then
    echo "[INFO] Supervisor 已在运行，跳过启动"
else
    echo "[INFO] 启动 Supervisor..."
    nohup python3 /root/loyanbot/supervisor.py >> "$LOG_DIR/supervisor_main.log" 2>&1 &
    sleep 2
    
    # 验证启动
    if pgrep -f "supervisor.py" > /dev/null; then
        echo "[OK] Supervisor 启动成功"
    else
        echo "[ERROR] Supervisor 启动失败"
        exit 1
    fi
fi

# 等待所有子进程启动
echo "[INFO] 等待保活进程启动..."
sleep 5

# 显示当前运行的进程
echo ""
echo "=== 当前运行状态 ==="
ps aux | grep -E "(supervisor|keeper|bot|http_server)" | grep -v grep
echo ""

# 显示最近的日志
echo "=== 最近日志 ==="
tail -10 "$LOG_DIR/supervisor.log" 2>/dev/null || echo "[WARN] 暂无 supervisor 日志"
echo ""

echo "=== 启动完成 ==="
echo "所有保活进程已启动"
echo "日志目录: $LOG_DIR"
