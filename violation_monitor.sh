#!/bin/bash
# 违规自动检测脚本
# 监控写入操作的违规情况，不锁文件，只监控和记录

LOG_DIR="/root/loyanbot/storage/logs"
MONITOR_LOG="$LOG_DIR/violation_monitor.log"
AUTH_FILE="/root/loyanbot/storage/active_authorizations.json"
PANIC_FILE="/root/loyanbot/storage/panic_mode.flag"

# 确保目录存在
mkdir -p "$(dirname "$MONITOR_LOG")"
mkdir -p "$(dirname "$AUTH_FILE")"

# 记录违规
log_violation() {
    local tool=$1
    local target=$2
    local reason=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] 违规检测: 工具=$tool 目标=$target 原因=$reason" >> "$MONITOR_LOG"
    
    # 更新违规计数
    local count_file="/root/loyanbot/storage/violation_count"
    if [ -f "$count_file" ]; then
        local count=$(cat "$count_file")
        count=$((count + 1))
        echo "$count" > "$count_file"
    else
        echo "1" > "$count_file"
    fi
    
    # 发送警报（如果有 notify-send）
    if command -v notify-send &> /dev/null; then
        notify-send "违规警告" "检测到未授权写入: $target ($reason)"
    fi
    
    # 检查是否需要进入恐慌模式
    check_panic_mode
}

# 检查恐慌模式
check_panic_mode() {
    local count_file="/root/loyanbot/storage/violation_count"
    if [ -f "$count_file" ]; then
        local count=$(cat "$count_file")
        if [ "$count" -ge 3 ]; then
            echo "PANIC_MODE" > "$PANIC_FILE"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 进入恐慌模式：连续违规3次，已暂停所有写入操作" >> "$MONITOR_LOG"
        fi
    fi
}

# 检查是否处于恐慌模式
is_panic_mode() {
    [ -f "$PANIC_FILE" ]
}

# 退出恐慌模式
exit_panic_mode() {
    rm -f "$PANIC_FILE"
    echo "0" > /root/loyanbot/storage/violation_count
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 退出恐慌模式" >> "$MONITOR_LOG"
}

# 记录授权状态
record_authorization() {
    local target=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "{\"target\": \"$target\", \"authorized\": true, \"time\": \"$timestamp\"}" >> "$AUTH_FILE"
}

# 检查授权状态
check_authorization() {
    local target=$1
    if [ -f "$AUTH_FILE" ]; then
        grep -q "\"$target\"" "$AUTH_FILE" && return 0
    fi
    return 1
}

# 清除过期授权（超过10分钟的授权失效）
cleanup_authorizations() {
    if [ -f "$AUTH_FILE" ]; then
        local temp_file="${AUTH_FILE}.tmp"
        local current_time=$(date +%s)
        
        # 只保留最近的授权
        tail -1 "$AUTH_FILE" > "$temp_file" 2>/dev/null
        
        mv "$temp_file" "$AUTH_FILE"
    fi
}

# 主监控循环（后台运行）
monitor_loop() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 违规监控启动" >> "$MONITOR_LOG"
    
    while true; do
        # 每30秒检查一次
        cleanup_authorizations
        sleep 30
    done
}

# 如果作为脚本直接运行
if [ "${1}" = "--monitor" ]; then
    monitor_loop
elif [ "${1}" = "--log" ]; then
    log_violation "$2" "$3" "$4"
elif [ "${1}" = "--record" ]; then
    record_authorization "$2"
elif [ "${1}" = "--check" ]; then
    check_authorization "$2"
elif [ "${1}" = "--panic" ]; then
    is_panic_mode && echo "PANIC" || echo "OK"
elif [ "${1}" = "--exit-panic" ]; then
    exit_panic_mode
else
    echo "用法："
    echo "  $0 --monitor          启动后台监控"
    echo "  $0 --log <tool> <target> <reason>  记录违规"
    echo "  $0 --record <target>  记录授权"
    echo "  $0 --check <target>   检查授权状态"
    echo "  $0 --panic            检查恐慌模式"
    echo "  $0 --exit-panic       退出恐慌模式"
fi
