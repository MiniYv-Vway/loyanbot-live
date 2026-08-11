#!/bin/bash
# 自动响应脚本 - 检测到违规立即行动
# 被guardian.py调用

VIOLATION_LOG="/root/loyanbot/violation_log.json"
RESPONSE_LOG="/root/loyanbot/auto_response.log"
ALERT_FILE="/root/loyanbot/alerts.json"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$RESPONSE_LOG"
}

# 检查违规次数
violation_count=$(python3 -c "import json; print(json.load(open('$VIOLATION_LOG')).get('total_violations', 0))" 2>/dev/null || echo "0")

log_msg "检测到第${violation_count}次违规"

# 根据违规次数执行不同响应
if [ "$violation_count" -ge 10 ]; then
    log_msg "严重违规：立即停止所有写入操作"
    # 锁定所有跟踪的文件
    python3 -c "
import json
with open('/tmp/write_tracker.json', 'r') as f:
    data = json.load(f)
for f in data.get('tracked_files', []):
    import subprocess
    subprocess.run(['chattr', '+i', f], capture_output=True)
"
    # 停止守护进程外的所有写入相关进程
    pkill -f "write_flow" 2>/dev/null
    pkill -f "write_lock" 2>/dev/null
    
elif [ "$violation_count" -ge 5 ]; then
    log_msg "严重违规：加强锁定"
    # 重新锁定所有文件
    python3 -c "
import json
with open('/tmp/write_tracker.json', 'r') as f:
    data = json.load(f)
for f in data.get('tracked_files', []):
    import subprocess
    subprocess.run(['chattr', '+i', f], capture_output=True)
"
    
elif [ "$violation_count" -ge 3 ]; then
    log_msg "警告：触发额外确认机制"
    # 添加额外确认要求
    echo "extra_confirm_required" > /tmp/write_extra_confirm.flag
fi

# 记录响应
python3 -c "
import json
from datetime import datetime
try:
    with open('$ALERT_FILE', 'r') as f:
        alerts = json.load(f)
except:
    alerts = {'alerts': [], 'total': 0}

alerts['alerts'].append({
    'time': datetime.now().isoformat(),
    'type': 'auto_response',
    'violation_count': $violation_count,
    'action': 'lockdown' if $violation_count >= 5 else 'warning'
})
alerts['total'] += 1

with open('$ALERT_FILE', 'w') as f:
    json.dump(alerts, f, indent=2, ensure_ascii=False)
"

log_msg "自动响应完成"
