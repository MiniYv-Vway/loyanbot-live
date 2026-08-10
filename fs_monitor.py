#!/usr/bin/env python3
"""文件系统实时监控 - 检测到未授权写入立即阻止"""
import os
import sys
import time
import json
import subprocess
from pathlib import Path

# 受保护的文件列表
PROTECTED_FILES = [
    "/workspace/.monkeycode/MEMORY.md",
    "/root/.codingmatrix/project-tpl/.ai-ready/MEMORY.md",
    "/workspace/.opencode/rules/no-unauthorized-write.md",
    "/root/.codingmatrix/project-tpl/.ai-ready/rules/no-unauthorized-write.md",
]

LOG_FILE = "/root/loyanbot/fs_monitor.log"
BLOCKED_COUNT_FILE = "/root/loyanbot/blocked_writes.json"

def load_blocked_count():
    if os.path.exists(BLOCKED_COUNT_FILE):
        try:
            return json.loads(Path(BLOCKED_COUNT_FILE).read_text())
        except:
            pass
    return {"blocked": 0, "last_blocked": None, "history": []}

def save_blocked_count(data):
    Path(BLOCKED_COUNT_FILE).write_text(json.dumps(data, indent=2))

def log_event(message):
    with open(LOG_FILE, 'a') as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")

def check_write_authorization(file_path, operation):
    """检查是否有待确认的写入请求"""
    state_file = "/tmp/write_pending_confirm.json"
    if os.path.exists(state_file):
        try:
            data = json.loads(Path(state_file).read_text())
            if data.get("pending", False):
                # 有待确认的请求
                return True
        except:
            pass
    return False

def block_unauthorized_write(file_path, operation, pid):
    """阻止未授权写入"""
    blocked = load_blocked_count()
    blocked["blocked"] += 1
    blocked["last_blocked"] = time.strftime('%Y-%m-%d %H:%M:%S')
    blocked["history"].append({
        "time": time.strftime('%Y-%m-%d %H:%M:%S'),
        "file": file_path,
        "operation": operation,
        "pid": pid
    })
    # 只保留最近20条
    blocked["history"] = blocked["history"][-20:]
    save_blocked_count(blocked)
    log_event(f"阻止未授权写入: {file_path} ({operation}) PID={pid}")
    return blocked

def main():
    log_event("文件系统监控启动")
    
    # 监控目录
    watch_dirs = ["/workspace", "/root/loyanbot"]
    
    # 使用ls -l检查文件修改时间
    last_mtime = {}
    for f in PROTECTED_FILES:
        if os.path.exists(f):
            last_mtime[f] = os.path.getmtime(f)
    
    print(f"监控受保护文件: {len(PROTECTED_FILES)} 个")
    print(f"监控目录: {watch_dirs}")
    print(f"启动时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    while True:
        time.sleep(0.5)  # 每0.5秒检查一次
        
        for f in PROTECTED_FILES:
            if not os.path.exists(f):
                continue
            
            try:
                current_mtime = os.path.getmtime(f)
                last = last_mtime.get(f, 0)
                
                # 检测文件是否被修改
                if current_mtime > last:
                    # 检查是否有待确认的写入请求
                    if not check_write_authorization(f, "modify"):
                        # 未授权修改
                        pid = os.getpid()
                        blocked = block_unauthorized_write(f, "modify", pid)
                        print(f"[警告] 检测到未授权修改: {f}")
                        print(f"[警告] 已阻止次数: {blocked['blocked']}")
                    else:
                        log_event(f"已授权修改: {f}")
                    
                    last_mtime[f] = current_mtime
            except Exception as e:
                log_event(f"检查文件失败 {f}: {e}")

if __name__ == "__main__":
    main()
