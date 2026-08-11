#!/usr/bin/env python3
"""
Skill级别写入保护
在skill执行层面强制确认
"""
import json
import os
import sys
from pathlib import Path

STATE_FILE = "/tmp/write_guardian/pending_confirm.json"
TRACKER_FILE = "/tmp/write_tracker.json"
VIOLATION_LOG = "/root/loyanbot/violation_log.json"

def check_skill_write_permission():
    """检查skill写入权限"""
    # 检查是否有待确认的请求
    if not os.path.exists(STATE_FILE):
        return False, "没有待确认的写入请求"
    
    try:
        with open(STATE_FILE, 'r') as f:
            data = json.load(f)
        
        if data.get('pending', False):
            return True, "写入请求已确认"
        else:
            return False, "请求已处理完毕"
    except:
        return False, "状态文件错误"

def record_skill_write(file_path, action):
    """记录skill写入操作"""
    try:
        with open(VIOLATION_LOG, 'r') as f:
            data = json.load(f)
    except:
        data = {'violations': [], 'total_violations': 0, 'last_violation': None}
    
    violation = {
        'time': __import__('datetime').datetime.now().isoformat(),
        'detail': f'Skill写入操作: {action} - {file_path}',
        'count': data['total_violations'] + 1,
        'source': 'skill'
    }
    
    data['violations'].append(violation)
    data['total_violations'] += 1
    data['last_violation'] = violation['time']
    
    with open(VIOLATION_LOG, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    return violation['count']

def main():
    if len(sys.argv) < 2:
        print("用法: skill_guard.py {check|record} [参数]")
        sys.exit(1)
    
    action = sys.argv[1]
    
    if action == "check":
        allowed, message = check_skill_write_permission()
        print(f"权限: {'允许' if allowed else '拒绝'}")
        print(f"原因: {message}")
        sys.exit(0 if allowed else 1)
    
    elif action == "record":
        if len(sys.argv) < 4:
            print("用法: skill_guard.py record <文件路径> <操作描述>")
            sys.exit(1)
        file_path = sys.argv[2]
        description = sys.argv[3]
        count = record_skill_write(file_path, description)
        print(f"已记录违规: 第{count}次")
        sys.exit(0)

if __name__ == "__main__":
    main()
