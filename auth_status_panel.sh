#!/bin/bash
# 授权状态面板
# 实时显示当前授权状态和违规情况

LOG_DIR="/root/loyanbot/storage/logs"
AUTH_FILE="/root/loyanbot/storage/active_authorizations.json"
COUNT_FILE="/root/loyanbot/storage/violation_count"
PANIC_FILE="/root/loyanbot/storage/panic_mode.flag"
MONITOR_LOG="$LOG_DIR/violation_monitor.log"

# 获取违规次数
get_violation_count() {
    if [ -f "$COUNT_FILE" ]; then
        cat "$COUNT_FILE"
    else
        echo "0"
    fi
}

# 检查恐慌模式
get_panic_status() {
    if [ -f "$PANIC_FILE" ]; then
        echo "已暂停"
    else
        echo "正常"
    fi
}

# 获取当前授权状态
get_current_auth() {
    if [ -f "$AUTH_FILE" ] && [ -s "$AUTH_FILE" ]; then
        local last_auth=$(tail -1 "$AUTH_FILE" 2>/dev/null)
        if echo "$last_auth" | grep -q '"authorized": true'; then
            echo "已授权"
        else
            echo "未授权"
        fi
    else
        echo "无授权"
    fi
}

# 获取最后授权时间
get_last_auth_time() {
    if [ -f "$AUTH_FILE" ] && [ -s "$AUTH_FILE" ]; then
        local last_auth=$(tail -1 "$AUTH_FILE" 2>/dev/null)
        echo "$last_auth" | grep -o '"time": "[^"]*"' | cut -d'"' -f4
    else
        echo "--"
    fi
}

# 获取最后违规时间
get_last_violation_time() {
    if [ -f "$MONITOR_LOG" ]; then
        tail -1 "$MONITOR_LOG" 2>/dev/null | grep -o '^\[.*\]' || echo "--"
    else
        echo "--"
    fi
}

# 显示面板
show_panel() {
    local violation_count=$(get_violation_count)
    local panic_status=$(get_panic_status)
    local current_auth=$(get_current_auth)
    local last_auth_time=$(get_last_auth_time)
    local last_violation_time=$(get_last_violation_time)
    
    # 清屏
    clear
    
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              写入授权状态面板 (no-unauthorized-write)        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  当前授权状态: $current_auth                                     ║"
    echo "║  最后授权时间: $last_auth_time                                ║"
    echo "║                                                            ║"
    echo "║  恐慌模式: $panic_status                                       ║"
    echo "║  违规次数: $violation_count 次                                  ║"
    echo "║  最后违规时间: $last_violation_time                            ║"
    echo "║                                                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  最近5条监控日志:                                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    
    if [ -f "$MONITOR_LOG" ]; then
        tail -5 "$MONITOR_LOG" 2>/dev/null | while read line; do
            printf "║  %-60s ║\n" "${line:0:60}"
        done
    else
        echo "║  暂无监控日志                                                  ║"
    fi
    
    echo "║                                                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  快捷键:                                                    ║"
    echo "║  [q] 退出  [r] 刷新  [c] 清除面板  [p] 退出恐慌模式            ║"
    echo "║                                                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
}

# 交互式模式
interactive_mode() {
    while true; do
        show_panel
        echo -n "请输入命令: "
        read -n 1 key
        
        case $key in
            q|Q)
                echo ""
                echo "退出面板"
                exit 0
                ;;
            r|R)
                # 刷新
                ;;
            c|C)
                clear
                ;;
            p|P)
                if [ -f "$PANIC_FILE" ]; then
                    /root/loyanbot/violation_monitor.sh --exit-panic
                fi
                ;;
        esac
    done
}

# 如果作为脚本直接运行
if [ "${1}" = "--panel" ]; then
    interactive_mode
elif [ "${1}" = "--status" ]; then
    show_panel
else
    show_panel
fi
