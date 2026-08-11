#!/bin/bash
# 总保活脚本 V2 - 最高层级的保活管理
# 功能：监控所有保活脚本，自动重启，日志轮转，健康检查

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/master_total_keepalive_v2.log"
PID_FILE="$LOG_DIR/master_total_keepalive_v2.pid"
CHECK_INTERVAL=5  # 每5秒检查一次

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查并重启单个脚本
restart_if_dead() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    # 检查进程是否运行
    if ! pgrep -f "$script_name" > /dev/null; then
        log "重启 $script_name..."
        bash "$script_path" &
        sleep 0.5
        if pgrep -f "$script_name" > /dev/null; then
            log "$script_name 重启成功"
        else
            log "$script_name 重启失败"
        fi
    fi
}

# 检查所有保活脚本
check_all() {
    local scripts_dir="/root/loyanbot/scripts"
    
    # 检查综合保活脚本 V2
    restart_if_dead "$scripts_dir/comprehensive_keepalive_v2.sh"
    
    # 检查各个独立脚本
    for script in network_keepalive.sh cpu_keepalive.sh io_keepalive.sh dns_keepalive.sh process_keepalive.sh api_keepalive.sh timer_keepalive.sh memory_keepalive.sh disk_keepalive.sh syscall_keepalive.sh log_keepalive.sh port_keepalive.sh signal_keepalive.sh thread_keepalive.sh fd_keepalive.sh env_keepalive.sh protocol_keepalive.sh service_keepalive.sh db_keepalive.sh cron_keepalive.sh; do
        if [ -f "$scripts_dir/$script" ]; then
            restart_if_dead "$scripts_dir/$script"
        fi
    done
    
    # 检查现有的保活脚本
    for script in /root/loyanbot/auto_keepalive.sh /root/loyanbot/master_keeper.sh /root/loyanbot/cron_keepalive.sh /root/loyanbot/network_keeper.sh; do
        if [ -f "$script" ]; then
            restart_if_dead "$script"
        fi
    done
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

# 健康检查
health_check() {
    log "=== 健康检查 ==="
    local total=0
    local running=0
    
    for script in /root/loyanbot/scripts/*.sh; do
        if [ -f "$script" ]; then
            local name=$(basename "$script")
            total=$((total + 1))
            if pgrep -f "$name" > /dev/null; then
                running=$((running + 1))
            fi
        fi
    done
    
    log "保活脚本总数：$total"
    log "运行中：$running"
    log "存活率：$((running * 100 / total))%"
    log "=== 检查完成 ==="
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "总保活脚本 V2 启动 PID=$$"

# 主循环
while true; do
    check_all
    rotate_logs
    health_check
    sleep $CHECK_INTERVAL
done
