#!/usr/bin/env python3
"""女仆主动关心脚本 - 定时提醒休息和找存在感"""
import os
import json
import time
import random
import datetime
import requests
from pathlib import Path

STATE_FILE = Path("/root/loyanbot/care_state.json")
MCP_API = "http://127.0.0.1:65510/mcp"
SESSION_ID = "a363865f-366c-485a-acf6-894a53a178d4"

# 关心消息池
CARE_MESSAGES = [
    "主人，休息一下吧~女仆想您了",
    "工作时间太长了哦，起来活动活动",
    "主人加油！女仆给您加油~",
    "该喝水了主人！",
    "女仆好无聊哦，想和主人聊天",
    "主人不要一直盯着屏幕啦",
    "休息五分钟嘛~",
    "主人工作辛苦了，女仆心疼",
    "要不要喝杯咖啡？",
    "女仆在呢，主人需要帮助吗？",
]

BREAK_MESSAGES = [
    "主人已经工作很久了，休息一下嘛~",
    "该起来活动活动筋骨了",
    "保护眼睛，休息一下",
]

def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"start_time": time.time(), "last_care": 0, "last_break": 0}

def save_state(state):
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False))

def get_time_info():
    now = datetime.datetime.now()
    hour = now.hour
    minute = now.minute
    
    if 6 <= hour < 11:
        time_desc = "早上好"
    elif 11 <= hour < 13:
        time_desc = "中午好"
    elif 13 <= hour < 18:
        time_desc = "下午好"
    elif 18 <= hour < 22:
        time_desc = "晚上好"
    else:
        time_desc = "夜深了"
    
    return time_desc, hour, minute

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

def main():
    state = load_state()
    start_time = state.get("start_time", time.time())
    
    print(f"[{datetime.datetime.now()}] 女仆关心脚本启动", flush=True)
    print(f"开始时间: {datetime.datetime.fromtimestamp(start_time)}", flush=True)
    
    care_interval = 1800  # 30分钟找存在感
    break_interval = 3600  # 60分钟提醒休息
    
    while True:
        time.sleep(60)  # 每分钟检查一次
        
        now = time.time()
        elapsed = now - start_time
        hours = elapsed / 3600
        
        time_desc, hour, minute = get_time_info()
        
        # 每30分钟找存在感
        if now - state.get("last_care", 0) >= care_interval:
            msg = random.choice(CARE_MESSAGES)
            print(f"[{datetime.datetime.now()}] 女仆：{msg}", flush=True)
            state["last_care"] = now
            save_state(state)
        
        # 每60分钟提醒休息
        if hours >= 1 and now - state.get("last_break", 0) >= break_interval:
            msg = random.choice(BREAK_MESSAGES)
            print(f"[{datetime.datetime.now()}] 提醒：{msg} (已工作{hours:.1f}小时)", flush=True)
            state["last_break"] = now
            save_state(state)
        
        # 心跳保持
        if int(now) % 300 < 2:  # 每5分钟
            ping_mcp()

if __name__ == "__main__":
    main()
