#!/bin/bash
# 超级总保活脚本 - 最高层级监控
# 功能：监控所有保活脚本，自动重启，确保100%存活

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/super_master_keepalive.log"
PID_FILE="$LOG_DIR/super_master_keepalive.pid"
CHECK_INTERVAL=3  # 每3秒检查一次

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 所有保活脚本列表
ALL_SCRIPTS=(
    "/root/loyanbot/scripts/network_keepalive.sh"
    "/root/loyanbot/scripts/cpu_keepalive.sh"
    "/root/loyanbot/scripts/io_keepalive.sh"
    "/root/loyanbot/scripts/dns_keepalive.sh"
    "/root/loyanbot/scripts/process_keepalive.sh"
    "/root/loyanbot/scripts/api_keepalive.sh"
    "/root/loyanbot/scripts/memory_keepalive.sh"
    "/root/loyanbot/scripts/disk_keepalive.sh"
    "/root/loyanbot/scripts/syscall_keepalive.sh"
    "/root/loyanbot/scripts/log_keepalive.sh"
    "/root/loyanbot/scripts/port_keepalive.sh"
    "/root/loyanbot/scripts/signal_keepalive.sh"
    "/root/loyanbot/scripts/thread_keepalive.sh"
    "/root/loyanbot/scripts/fd_keepalive.sh"
    "/root/loyanbot/scripts/env_keepalive.sh"
    "/root/loyanbot/scripts/protocol_keepalive.sh"
    "/root/loyanbot/scripts/service_keepalive.sh"
    "/root/loyanbot/scripts/db_keepalive.sh"
    "/root/loyanbot/scripts/cron_keepalive.sh"
    "/root/loyanbot/scripts/ultra_network_keepalive.sh"
    "/root/loyanbot/scripts/ultra_cpu_keepalive.sh"
    "/root/loyanbot/scripts/cross_monitor_keepalive.sh"
    "/root/loyanbot/scripts/multi_backup_keepalive.sh"
    "/root/loyanbot/scripts/system_keepalive.sh"
    "/root/loyanbot/scripts/network_stack_keepalive.sh"
    "/root/loyanbot/scripts/file_lock_keepalive.sh"
    "/root/loyanbot/scripts/semaphore_keepalive.sh"
    "/root/loyanbot/scripts/pipe_keepalive.sh"
    "/root/loyanbot/scripts/shared_mem_keepalive.sh"
    "/root/loyanbot/scripts/process_group_keepalive.sh"
    "/root/loyanbot/scripts/timer_keepalive_v2.sh"
    "/root/loyanbot/scripts/event_keepalive.sh"
    "/root/loyanbot/scripts/queue_keepalive.sh"
    "/root/loyanbot/scripts/thread_pool_keepalive.sh"
    "/root/loyanbot/scripts/async_io_keepalive.sh"
    "/root/loyanbot/scripts/network_dns_keepalive.sh"
    "/root/loyanbot/scripts/network_http_keepalive.sh"
)

# 检查并重启单个脚本
restart_if_dead() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    if ! pgrep -f "$script_name" > /dev/null; then
        log "重启 $script_name..."
        bash "$script_path" &
        sleep 0.3
        if pgrep -f "$script_name" > /dev/null; then
            log "$script_name 重启成功"
        else
            log "$script_name 重启失败"
        fi
    fi
}

# 检查所有保活脚本
check_all() {
    for script in "${ALL_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            restart_if_dead "$script"
        fi
    done
}

# 健康检查
health_check() {
    local total=${#ALL_SCRIPTS[@]}
    local running=0
    
    for script in "${ALL_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            local name=$(basename "$script")
            if pgrep -f "$name" > /dev/null; then
                running=$((running + 1))
            fi
        fi
    done
    
    log "=== 健康检查 ==="
    log "保活脚本总数：$total"
    log "运行中：$running"
    log "存活率：$((running * 100 / total))%"
    log "=== 检查完成 ==="
}

# 日志轮转
rotate_logs() {
    local max_size=5242880  # 5MB
    
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

echo $$ > "$PID_FILE"
log "超级总保活脚本启动 PID=$$"

while true; do
    check_all
    rotate_logs
    health_check
    sleep $CHECK_INTERVAL
done
