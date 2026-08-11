#!/bin/bash
# 交叉监控保活 - 监控所有保活进程
# 策略：每3秒检查一次，自动重启死掉的进程

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/cross_monitor_keepalive.log"
PID_FILE="$LOG_DIR/cross_monitor_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 交叉监控
cross_monitor() {
    local scripts=(
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
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local name=$(basename "$script")
            if ! pgrep -f "$name" > /dev/null; then
                log "重启 $name..."
                bash "$script" &
                sleep 0.5
            fi
        fi
    done
}

echo $$ > "$PID_FILE"
log "交叉监控保活启动 PID=$$"

while true; do
    cross_monitor
    log "交叉监控完成"
    sleep 3
done
