#!/bin/bash
# 严格写入守卫脚本 - 最强版
# 规则：只有用户说"同意执行"四个字才能执行写入

GUARD_FILE="/root/loyanbot/strict_write_guard.txt"
VIOLATION_LOG="/root/loyanbot/violation_log.json"

# 检查守卫状态
check_guard() {
    if [ -f "$GUARD_FILE" ]; then
        cat "$GUARD_FILE"
    else
        echo "ACTIVE|2026-08-11T00:00:00"
    fi
}

# 记录违规
log_violation() {
    local violation_type="$1"
    local detail="$2"
    local timestamp=$(date -Iseconds)
    local count=$(python3 -c "import json; d=json.load(open('$VIOLATION_LOG')); print(d['total_violations']+1)" 2>/dev/null || echo 1)
    
    python3 -c "
import json
from datetime import datetime
log_file = '$VIOLATION_LOG'
try:
    with open(log_file, 'r') as f:
        data = json.load(f)
except:
    data = {'violations': [], 'total_violations': 0}

data['violations'].append({
    'time': '$timestamp',
    'type': '$violation_type',
    'detail': '$detail',
    'count': $count
})
data['total_violations'] = $count
data['last_violation'] = '$timestamp'

with open(log_file, 'w') as f:
    json.dump(data, f, indent=2)
"
}

# 主函数
case "$1" in
    check)
        check_guard
        ;;
    log)
        log_violation "$2" "$3"
        ;;
    status)
        echo "严格写入守卫 - 最强版"
        echo "规则：只有用户说'同意执行'四个字才能执行写入"
        echo "其他任何输入 = 只读模式"
        echo "违规记录: $(python3 -c "import json; print(json.load(open('$VIOLATION_LOG'))['total_violations'])" 2>/dev/null || echo 0)"
        ;;
    *)
        echo "用法: $0 {check|log|status}"
        exit 1
        ;;
esac
