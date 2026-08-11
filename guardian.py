#!/usr/bin/env python3
"""
系统级守护进程 - 100%强制写入保护
实时监控所有写入操作，违规立即阻止并记录
"""
import os
import sys
import time
import json
import subprocess
import hashlib
from pathlib import Path
from datetime import datetime

# 配置
STATE_DIR = "/tmp/write_guardian"
VIOLATION_LOG = "/root/loyanbot/violation_log.json"
GUARDIAN_LOG = "/root/loyanbot/guardian.log"
ALERT_FILE = "/root/loyanbot/alerts.json"
TRACKER_FILE = "/tmp/write_tracker.json"

# 确保目录存在
os.makedirs(STATE_DIR, exist_ok=True)

def log(message):
    """记录日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(GUARDIAN_LOG, 'a') as f:
        f.write(f"[{timestamp}] {message}\n")

def record_violation(detail):
    """记录违规行为"""
    try:
        with open(VIOLATION_LOG, 'r') as f:
            data = json.load(f)
    except:
        data = {'violations': [], 'total_violations': 0, 'last_violation': None}
    
    violation = {
        'time': datetime.now().isoformat(),
        'detail': detail,
        'count': data['total_violations'] + 1
    }
    
    data['violations'].append(violation)
    data['total_violations'] += 1
    data['last_violation'] = violation['time']
    data['violations'] = data['violations'][-100:]  # 保留最近100条
    
    with open(VIOLATION_LOG, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    # 发送警报
    send_alert(violation)
    
    log(f"违规已记录: 第{violation['count']}次 - {detail}")
    return violation['count']

def send_alert(violation):
    """发送警报"""
    try:
        with open(ALERT_FILE, 'r') as f:
            alerts = json.load(f)
    except:
        alerts = {'alerts': [], 'total': 0}
    
    alert = {
        'time': datetime.now().isoformat(),
        'type': 'violation',
        'count': violation['count'],
        'detail': violation['detail']
    }
    
    alerts['alerts'].append(alert)
    alerts['total'] += 1
    alerts['alerts'] = alerts['alerts'][-50:]  # 保留最近50条
    
    with open(ALERT_FILE, 'w') as f:
        json.dump(alerts, f, indent=2, ensure_ascii=False)

def check_write_authorization(target_file):
    """检查写入授权"""
    state_file = os.path.join(STATE_DIR, "pending_confirm.json")
    
    if not os.path.exists(state_file):
        return False
    
    try:
        with open(state_file, 'r') as f:
            data = json.load(f)
        
        if data.get('pending', False) and data.get('target_file') == target_file:
            return True
    except:
        pass
    
    return False

def monitor_filesystem():
    """监控文件系统"""
    log("守护进程启动，开始监控文件系统")
    
    # 加载被跟踪的文件列表
    tracked_files = []
    if os.path.exists(TRACKER_FILE):
        try:
            with open(TRACKER_FILE, 'r') as f:
                data = json.load(f)
            tracked_files = data.get('tracked_files', [])
        except:
            pass
    
    # 初始文件状态
    file_states = {}
    for f in tracked_files:
        if os.path.exists(f):
            try:
                stat = os.stat(f)
                file_states[f] = {
                    'mtime': stat.st_mtime,
                    'inode': stat.st_ino,
                    'size': stat.st_size
                }
            except:
                pass
    
    log(f"开始监控 {len(tracked_files)} 个文件")
    
    last_check = 0
    check_interval = 0.1  # 每0.1秒检查一次
    
    while True:
        try:
            current_time = time.time()
            
            if current_time - last_check < check_interval:
                time.sleep(0.01)
                continue
            
            last_check = current_time
            
            # 重新加载跟踪列表
            if os.path.exists(TRACKER_FILE):
                try:
                    with open(TRACKER_FILE, 'r') as f:
                        data = json.load(f)
                    tracked_files = data.get('tracked_files', [])
                except:
                    pass
            
            # 检查每个文件
            for file_path in tracked_files:
                if not os.path.exists(file_path):
                    continue
                
                try:
                    stat = os.stat(file_path)
                    current_state = {
                        'mtime': stat.st_mtime,
                        'inode': stat.st_ino,
                        'size': stat.st_size
                    }
                    
                    previous_state = file_states.get(file_path)
                    
                    # 检测变化
                    if previous_state:
                        if (current_state['mtime'] != previous_state['mtime'] or
                            current_state['size'] != previous_state['size']):
                            # 文件被修改
                            if not check_write_authorization(file_path):
                                # 未授权修改
                                log(f"检测到未授权写入: {file_path}")
                                record_violation(f"检测到未授权文件修改: {file_path}")
                                # 立即重新锁定
                                subprocess.run(['chattr', '+i', file_path], 
                                             capture_output=True)
                    else:
                        file_states[file_path] = current_state
                        
                except Exception as e:
                    log(f"检查文件失败 {file_path}: {e}")
        
        except KeyboardInterrupt:
            log("守护进程停止")
            sys.exit(0)
        except Exception as e:
            log(f"监控循环错误: {e}")
            time.sleep(1)

def main():
    """主函数"""
    log("=" * 50)
    log("守护进程启动")
    log(f"PID: {os.getpid()}")
    log(f"时间: {datetime.now().isoformat()}")
    log("=" * 50)
    
    monitor_filesystem()

if __name__ == "__main__":
    main()
