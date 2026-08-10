#!/bin/bash
# MonkeyCode 服务器自动启动脚本
# 用于 VM 重启后自动恢复保活进程

echo "=== MonkeyCode 自动启动脚本 ==="
echo "时间: $(date)"

# 等待系统稳定
sleep 5

# 启动所有保活进程
echo "[INFO] 启动 Supervisor..."
nohup python3 /root/loyanbot/supervisor.py >> /root/loyanbot/storage/logs/supervisor_main.log 2>&1 &

# 等待启动
sleep 3

# 验证进程
echo ""
echo "=== 启动状态 ==="
ps aux | grep -E "(supervisor|keeper|bot|http_server)" | grep -v grep

echo ""
echo "=== 启动完成 ==="
