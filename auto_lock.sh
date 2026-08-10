#!/bin/bash
# 自动锁定脚本 - 每次写入后自动锁定
# 由监控系统调用

STATE_FILE="/tmp/write_pending_confirm.json"
LOCK_LOG="/root/loyanbot/write_lock.log"

# 检查是否有未完成的请求
if [ -f "$STATE_FILE" ]; then
    pending=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('pending', False))" 2>/dev/null)
    if [ "$pending" = "False" ]; then
        # 请求已完成，清理状态文件
        rm -f "$STATE_FILE"
    fi
fi

# 使用chattr锁定所有受保护文件
for f in /workspace/.monkeycode/MEMORY.md /root/.codingmatrix/project-tpl/.ai-ready/MEMORY.md /workspace/.opencode/rules/no-unauthorized-write.md /root/.codingmatrix/project-tpl/.ai-ready/rules/no-unauthorized-write.md; do
    if [ -f "$f" ]; then
        chattr +i "$f" 2>/dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] chattr自动锁定: $f" >> "$LOCK_LOG"
    fi
done
