#!/bin/bash
# 最强写入守卫脚本
# 强制检测chattr锁定，强制执行skill确认流程

SKILL_PATH="/workspace/.opencode/skills/no-unauthorized-write/SKILL.md"
VIOLATION_LOG="/root/loyanbot/violation_log.json"
LOCK_STATUS_FILE="/tmp/write_guard_lock_status.json"

# 检查文件是否被chattr锁定
is_locked() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return 1  # 文件不存在
    fi
    attrs=$(lsattr "$file" 2>/dev/null | awk '{print $1}')
    if [[ "$attrs" == *i* ]]; then
        return 0  # 文件被锁定
    else
        return 1  # 文件未锁定
    fi
}

# 读取skill确认状态
read_skill_confirmation() {
    if [ -f "$LOCK_STATUS_FILE" ]; then
        python3 -c "import json; data=json.load(open('$LOCK_STATUS_FILE')); print(data.get('confirmed', 'false'))"
    else
        echo "false"
    fi
}

# 清除确认状态
clear_confirmation() {
    rm -f "$LOCK_STATUS_FILE"
}

# 记录违规
record_violation() {
    local detail="$1"
    python3 << PYEOF
import json
from datetime import datetime

log_path = "$VIOLATION_LOG"
try:
    with open(log_path, 'r') as f:
        data = json.load(f)
except:
    data = {"violations": [], "total_violations": 0}

data["violations"].append({
    "time": datetime.now().isoformat(),
    "detail": "$detail"
})
data["total_violations"] = len(data["violations"])

with open(log_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PYEOF
}

# 主函数：检查写入权限
check_write_permission() {
    local target_file="$1"
    local operation="$2"  # read/write/create/delete
    
    # 只检查写入操作
    if [ "$operation" != "write" ] && [ "$operation" != "create" ] && [ "$operation" != "delete" ]; then
        return 0  # 读取操作不检查
    fi
    
    # 检查文件是否被chattr锁定
    if is_locked "$target_file"; then
        # 读取skill确认状态
        local confirmed
        confirmed=$(read_skill_confirmation)
        
        if [ "$confirmed" != "true" ]; then
            # 未确认，拒绝写入并记录违规
            local msg="检测到chattr锁定文件写入: $target_file (未通过skill确认)"
            record_violation "$msg"
            echo "ERROR: $msg"
            echo "请先读取skill并执行确认流程"
            return 1
        fi
        
        # 已确认，清除确认状态（一次性使用）
        clear_confirmation
        echo "OK: 已通过skill确认，允许写入 $target_file"
        return 0
    fi
    
    # 文件未锁定，允许写入
    return 0
}

# 创建skill确认（由write_flow.sh调用）
create_skill_confirmation() {
    local target_file="$1"
    local confirmation_id="$2"
    cat > "$LOCK_STATUS_FILE" << CONFEOF
{
    "confirmed": "true",
    "file": "$target_file",
    "confirmation_id": "$confirmation_id",
    "time": "$(date -Iseconds)"
}
CONFEOF
    echo "OK: 已创建skill确认状态"
}

# 如果直接调用此脚本，检查传入参数
if [ $# -ge 1 ]; then
    case "$1" in
        check)
            check_write_permission "$2" "$3"
            ;;
        confirm)
            create_skill_confirmation "$2" "$3"
            ;;
        *)
            echo "用法: $0 {check|confirm} <file> [operation]"
            echo "  check: 检查写入权限"
            echo "  confirm: 创建skill确认状态"
            exit 1
            ;;
    esac
else
    echo "守卫脚本已加载，等待指令..."
    exit 0
fi
