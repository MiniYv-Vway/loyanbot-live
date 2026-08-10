#!/bin/bash
# 启动女仆关心脚本
nohup python3 /root/loyanbot/care.py >> /root/loyanbot/care.log 2>&1 &
echo "女仆关心脚本已启动 PID: $!"
