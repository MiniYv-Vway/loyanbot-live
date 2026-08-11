#!/bin/bash
# 综合保活脚本 - 统一管理所有保活脚本
# 功能：启动、停止、重启、状态检查

SCRIPT_DIR="/root/loyanbot/scripts"
LOG_DIR="/root/loyanbot/storage/logs"
MASTER_LOG="$LOG_DIR/comprehensive_keepalive.log"
MASTER_PID="$LOG_DIR/comprehensive_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MASTER_LOG"
}

# 保活脚本列表
KEEPALIVE_SCRIPTS=(
    "network_keepalive.sh"
    "cpu_keepalive.sh"
    "io_keepalive.sh"
    "dns_keepalive.sh"
    "process_keepalive.sh"
    "api_keepalive.sh"
    "timer_keepalive.sh"
)

# 启动所有保活脚本
start_all() {
    log "启动所有保活脚本..."
    
    for script in "${KEEPALIVE_SCRIPTS[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            # 检查是否已运行
            if pgrep -f "$script" > /dev/null; then
                log "$script 已在运行"
            else
                # 启动脚本
                bash "$SCRIPT_DIR/$script" &
                log "启动 $script"
                sleep 1
            fi
        else
            log "警告：$script 不存在"
        fi
    done
    
    log "所有保活脚本启动完成"
}

# 停止所有保活脚本
stop_all() {
    log "停止所有保活脚本..."
    
    for script in "${KEEPALIVE_SCRIPTS[@]}"; do
        # 查找并终止进程
        pids=$(pgrep -f "$script" 2>/dev/null)
        if [ -n "$pids" ]; then
            kill $pids 2>/dev/null
            log "停止 $script"
            sleep 1
        fi
    done
    
    # 终止自身
    pids=$(pgrep -f "comprehensive_keepalive.sh" 2>/dev/null)
    if [ -n "$pids" ]; then
        kill $pids 2>/dev/null
    fi
    
    log "所有保活脚本已停止"
}

# 检查所有保活脚本状态
check_all() {
    log "=== 检查保活脚本状态 ==="
    
    local running=0
    local stopped=0
    
    for script in "${KEEPALIVE_SCRIPTS[@]}"; do
        if pgrep -f "$script" > /dev/null; then
            running=$((running + 1))
            log "$script: 运行中"
        else
            stopped=$((stopped + 1))
            log "$script: 已停止"
        fi
    done
    
    log "运行中：$running, 已停止：$stopped"
    log "=== 检查完成 ==="
}

# 重启所有保活脚本
restart_all() {
    log "重启所有保活脚本..."
    stop_all
    sleep 2
    start_all
}

# 生成健康报告
health_report() {
    log "=== 健康报告 ==="
    log "时间：$(date '+%Y-%m-%d %H:%M:%S')"
    log "保活脚本数量：${#KEEPALIVE_SCRIPTS[@]}"
    
    local running=0
    local stopped=0
    
    for script in "${KEEPALIVE_SCRIPTS[@]}"; do
        if pgrep -f "$script" > /dev/null; then
            running=$((running + 1))
        else
            stopped=$((stopped + 1))
        fi
    done
    
    log "运行中：$running/${#KEEPALIVE_SCRIPTS[@]}"
    log "已停止：$stopped/${#KEEPALIVE_SCRIPTS[@]}"
    log "=== 报告结束 ==="
}

# 主逻辑
case "${1:-status}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status|check)
        check_all
        ;;
    health)
        health_report
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|health}"
        exit 1
        ;;
esac

exit 0
