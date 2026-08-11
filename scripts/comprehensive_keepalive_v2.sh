#!/bin/bash
# 综合保活脚本 V2 - 加强版，统一管理所有保活脚本
# 功能：启动、停止、重启、状态检查、日志管理

SCRIPT_DIR="/root/loyanbot/scripts"
LOG_DIR="/root/loyanbot/storage/logs"
MASTER_LOG="$LOG_DIR/comprehensive_keepalive_v2.log"
MASTER_PID="$LOG_DIR/comprehensive_keepalive_v2.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MASTER_LOG"
}

# 保活脚本列表（增强版）
KEEPALIVE_SCRIPTS=(
    "network_keepalive.sh"
    "cpu_keepalive.sh"
    "io_keepalive.sh"
    "dns_keepalive.sh"
    "process_keepalive.sh"
    "api_keepalive.sh"
    "timer_keepalive.sh"
    "memory_keepalive.sh"
    "disk_keepalive.sh"
    "syscall_keepalive.sh"
    "log_keepalive.sh"
    "port_keepalive.sh"
    "signal_keepalive.sh"
    "thread_keepalive.sh"
    "fd_keepalive.sh"
    "env_keepalive.sh"
    "protocol_keepalive.sh"
    "service_keepalive.sh"
    "db_keepalive.sh"
    "cron_keepalive.sh"
)

# 启动所有保活脚本
start_all() {
    log "启动所有保活脚本（V2增强版）..."
    
    local started=0
    local failed=0
    
    for script in "${KEEPALIVE_SCRIPTS[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            # 检查是否已运行
            if pgrep -f "$script" > /dev/null; then
                log "$script 已在运行"
            else
                # 启动脚本
                bash "$SCRIPT_DIR/$script" &
                log "启动 $script"
                sleep 0.5
                started=$((started + 1))
            fi
        else
            log "警告：$script 不存在"
            failed=$((failed + 1))
        fi
    done
    
    log "启动完成：成功=$started, 失败=$failed"
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
            sleep 0.5
        fi
    done
    
    # 终止自身
    pids=$(pgrep -f "comprehensive_keepalive_v2.sh" 2>/dev/null)
    if [ -n "$pids" ]; then
        kill $pids 2>/dev/null
    fi
    
    log "所有保活脚本已停止"
}

# 检查所有保活脚本状态
check_all() {
    log "=== 检查保活脚本状态（V2）==="
    
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
    
    log "运行中：$running, 已停止：$stopped, 总计：${#KEEPALIVE_SCRIPTS[@]}"
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
    log "=== 健康报告（V2增强版）==="
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
    log "活跃度：$((running * 100 / ${#KEEPALIVE_SCRIPTS[@]}))%"
    log "=== 报告结束 ==="
}

# 日志轮转
rotate_logs() {
    local max_size=10485760  # 10MB
    
    for log_file in "$LOG_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            local size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
            if [ "$size" -gt "$max_size" ]; then
                log "轮转日志：$log_file"
                mv "$log_file" "$log_file.$(date +%s).bak"
                touch "$log_file"
            fi
        fi
    done
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
    rotate)
        rotate_logs
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|health|rotate}"
        exit 1
        ;;
esac

exit 0
