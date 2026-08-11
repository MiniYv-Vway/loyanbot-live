#!/usr/bin/env python3
"""
违规后自动锁定机制
检测到违规立即停止所有写入权限
"""
import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime

STATE_DIR = "/tmp/write_guardian"
LOCK_STATE = os.path.join(STATE_DIR, "write_locked.json")
VIOLATION_LOG = "/root/loyanbot/violation_log.json"
TRACKER_FILE = "/tmp/write_tracker.json"

def load_lock_state():
    """加载锁定状态"""
    if os.path.exists(LOCK_STATE):
        with open(LOCK_STATE, 'r') as f:
            return json.load(f)
    return {'locked': False, 'reason': '', 'locked_at': None, 'violation_count': 0}

def save_lock_state(state):
    """保存锁定状态"""
    with open(LOCK_STATE, 'w') as f:
        json.dump(state, f, indent=2)

def check_and_lock():
    """检查并执行锁定"""
    state = load_lock_state()
    
    # 读取违规记录
    try:
        with open(VIOLATION_LOG, 'r') as f:
            violation_data = json.load(f)
        current_count = violation_data.get('total_violations', 0)
    except:
        current_count = 0
    
    # 如果违规次数增加，执行锁定
    if current_count > state.get('violation_count', 0):
        # 锁定所有跟踪的文件
        locked_files = []
        if os.path.exists(TRACKER_FILE):
            try:
                with open(TRACKER_FILE, 'r') as f:
                    tracker_data = json.load(f)
                for file_path in tracker_data.get('tracked_files', []):
                    result = subprocess.run(['chattr', '+i', file_path], 
                                          capture_output=True)
                    if result.returncode == 0:
                        locked_files.append(file_path)
            except:
                pass
        
        # 更新锁定状态
        new_state = {
            'locked': True,
            'reason': f'第{current_count}次违规',
            'locked_at': datetime.now().isoformat(),
            'violation_count': current_count,
            'locked_files': locked_files
        }
        save_lock_state(new_state)
        
        print(f"已锁定 {len(locked_files)} 个文件")
        print(f"原因: {new_state['reason']}")
        print(f"时间: {new_state['locked_at']}")
        return True
    
    return False

def check_permission():
    """检查是否有写入权限"""
    state = load_lock_state()
    if state.get('locked', False):
        return False, f"写入权限已锁定: {state['reason']}"
    return True, "有写入权限"

def unlock_with_password(password):
    """用密码解锁"""
    # 这里应该验证密码
    # 简化版本：直接解锁
    state = load_lock_state()
    state['locked'] = False
    state['unlock_time'] = datetime.now().isoformat()
    save_lock_state(state)
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: violation_lock.py {check|lock|unlock}")
        sys.exit(1)
    
    action = sys.argv[1]
    
    if action == "check":
        allowed, message = check_permission()
        print(f"权限: {'允许' if allowed else '拒绝'}")
        print(f"原因: {message}")
        sys.exit(0 if allowed else 1)
    
    elif action == "lock":
        if check_and_lock():
            print("锁定执行成功")
        else:
            print("无需锁定")
    
    elif action == "unlock":
        if len(sys.argv) > 2:
            password = sys.argv[2]
            if unlock_with_password(password):
                print("解锁成功")
            else:
                print("解锁失败")
                sys.exit(1)
        else:
            print("需要提供密码")
            sys.exit(1)
