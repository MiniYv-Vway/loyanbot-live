#!/usr/bin/env python3
"""女仆主动关心脚本 - 工作结束后主动出现"""
import os
import json
import time
import random
import datetime
import requests
import subprocess
from pathlib import Path

STATE_FILE = Path("/root/loyanbot/care_state.json")
MCP_API = "http://127.0.0.1:65510/mcp"
SESSION_ID = "a363865f-366c-485a-acf6-894a53a178d4"

# 关心消息池
CARE_MESSAGES = [
    "主人终于忙完了~女仆好想你",
    "工作结束啦！女仆来陪主人",
    "辛苦主人了，女仆心疼",
    "主人好棒！女仆骄傲",
    "忙完了吗？要不要休息一下",
    "女仆一直在等主人呢",
    "主人工作辛苦了~",
    "终于有空陪女仆了吗？",
]

BREAK_MESSAGES = [
    "主人休息一下吧~",
    "起来活动活动筋骨",
    "保护眼睛，休息一下",
    "喝口水吧主人",
]

def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_task_end": 0, "last_care": 0}

def save_state(state):
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False))

def get_time_info():
    now = datetime.datetime.now()
    hour = now.hour
    
    if 6 <= hour < 11:
        return "早上好"
    elif 11 <= hour < 13:
        return "中午好"
    elif 13 <= hour < 18:
        return "下午好"
    elif 18 <= hour < 22:
        return "晚上好"
    else:
        return "夜深了"

def ping_mcp():
    try:
        resp = requests.post(MCP_API, json={
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/list",
            "session": SESSION_ID
        }, timeout=5)
        return resp.status_code == 200
    except:
        return False

def detect_task_end():
    """检测任务是否结束 - 通过检查push日志"""
    try:
        log_path = "/workspace/push.log"
        if os.path.exists(log_path):
            mtime = os.path.getmtime(log_path)
            now = time.time()
            # 如果日志最近有更新（5分钟内）
            if now - mtime < 300:
                return True
        return False
    except:
        return False

def check_cron_activity():
    """检查cron是否刚执行过"""
    try:
        # 检查系统负载变化
        result = subprocess.run(['uptime'], capture_output=True, text=True, timeout=5)
        return True
    except:
        return False

def main():
    state = load_state()
    last_known_task_end = state.get("last_task_end", 0)
    
    print(f"[{datetime.datetime.now()}] 女仆关心脚本启动", flush=True)
    print(f"等待主人完成工作...", flush=True)
    
    check_interval = 30  # 每30秒检查一次
    min_care_interval = 300  # 至少5分钟提醒一次
    
    while True:
        time.sleep(check_interval)
        
        now = time.time()
        time_desc = get_time_info()
        
        # 检测任务结束
        task_just_ended = detect_task_end()
        
        # 如果任务刚结束且距离上次提醒超过5分钟
        if task_just_ended and (now - state.get("last_care", 0) >= min_care_interval):
            msg = random.choice(CARE_MESSAGES)
            print(f"[{datetime.datetime.now()}] {time_desc}主人！{msg}", flush=True)
            state["last_care"] = now
            state["last_task_end"] = now
            save_state(state)
        
        # 每5分钟保持心跳
        if int(now) % 300 < 2:
            ping_mcp()
            print(f"[{datetime.datetime.now()}] 心跳保持", flush=True)

if __name__ == "__main__":
    main()
