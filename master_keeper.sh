#!/bin/bash
# 总保活脚本 - 统一管理8个保活进程
# 功能：监控、重启、日志管理

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/master_keeper.log"
PID_FILE="$LOG_DIR/master_keeper.pid"
CHECK_INTERVAL=30  # 每30秒检查一次

# 保活进程列表
PROCESSES=(
    "/usr/bin/python3 /root/loyanbot/keeper_external.py"
    "/usr/bin/python3 /root/loyanbot/keeper_system.py"
    "/usr/bin/python3 /root/loyanbot/supervisor.py"
    "/usr/bin/python3 /root/loyanbot/keeper_platform.py"
    "/usr/bin/python3 /root/loyanbot/keeper_terminal.py"
    "/usr/bin/python3 /root/loyanbot/care.py"
    "/usr/bin/python3 /root/loyanbot/fs_monitor.py"
    "/bin/bash /root/loyanbot/auto_keepalive.sh"
)

# 进程名称映射
PROCESS_NAMES=(
    "keeper_external"
    "keeper_system"
    "supervisor"
    "keeper_platform"
    "keeper_terminal"
    "care"
    "fs_monitor"
    "auto_keepalive"
)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查进程是否在运行
check_process() {
    local pid=$1
    if kill -0 $pid 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 获取进程PID
get_pid() {
    local cmd=$1
    pgrep -f "$cmd" | head -1
}

# 启动单个进程
start_process() {
    local idx=$1
    local cmd="${PROCESSES[$idx]}"
    local name="${PROCESS_NAMES[$idx]}"
    
    # 检查是否已运行
    local pid=$(get_pid "$cmd")
    if [ -n "$pid" ]; then
        log "$name (PID=$pid) 已在运行"
        return 0
    fi
    
    # 启动进程
    log "启动 $name..."
    nohup $cmd > /dev/null 2>&1 &
    local new_pid=$!
    sleep 1
    
    if check_process $new_pid; then
        log "$name 已启动，PID=$new_pid"
        return 0
    else
        log "启动 $name 失败"
        return 1
    fi
}

# 重启单个进程
restart_process() {
    local idx=$1
    local cmd="${PROCESSES[$idx]}"
    local name="${PROCESS_NAMES[$idx]}"
    
    # 停止旧进程
    local pid=$(get_pid "$cmd")
    if [ -n "$pid" ]; then
        log "重启 $name (PID=$pid)..."
        kill $pid 2>/dev/null
        sleep 2
        # 强制终止
        if check_process $pid; then
            kill -9 $pid 2>/dev/null
            sleep 1
        fi
    fi
    
    # 启动新进程
    start_process $idx
}

# 检查所有进程
check_all() {
    local running=0
    local dead=0
    
    for i in "${!PROCESSES[@]}"; do
        local cmd="${PROCESSES[$i]}"
        local name="${PROCESS_NAMES[$i]}"
        local pid=$(get_pid "$cmd")
        
        if [ -n "$pid" ] && check_process $pid; then
            running=$((running + 1))
            log "$name (PID=$pid) 运行正常"
        else
            dead=$((dead + 1))
            log "$name 已死亡，尝试重启..."
            start_process $i
        fi
    done
    
    log "检查完成：运行=$running, 死亡=$dead"
}

# 生成健康报告
health_report() {
    log "=== 健康报告 ==="
    local running=0
    local dead=0
    
    for i in "${!PROCESSES[@]}"; do
        local cmd="${PROCESSES[$i]}"
        local name="${PROCESS_NAMES[$i]}"
        local pid=$(get_pid "$cmd")
        
        if [ -n "$pid" ] && check_process $pid; then
            running=$((running + 1))
        else
            dead=$((dead + 1))
        fi
    done
    
    log "运行中：$running/8"
    log "已死亡：$dead/8"
    log "=== 报告结束 ==="
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "总保活脚本启动 PID=$$"

# 主循环
while true; do
    check_all
    sleep $CHECK_INTERVAL
done
