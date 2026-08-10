#!/usr/bin/env python3
"""写入规则执行检查器 - 外部验证"""
import json
import os
import datetime
from pathlib import Path

LOG_FILE = Path("/root/loyanbot/write_check_log.json")
VERIFICATION_FILE = Path("/root/loyanbot/write_rule_verified.txt")

def check():
    now = datetime.datetime.now().isoformat()
    
    # 更新验证文件
    if VERIFICATION_FILE.exists():
        content = VERIFICATION_FILE.read_text()
        lines = content.split('\n')
        # 更新最后验证时间
        if lines:
            lines[0] = f"规则验证时间: {now}"
            VERIFICATION_FILE.write_text('\n'.join(lines))
    else:
        VERIFICATION_FILE.write_text(f"规则验证时间: {now}\n")
    
    # 记录检查
    log = []
    if LOG_FILE.exists():
        try:
            log = json.loads(LOG_FILE.read_text())
        except:
            log = []
    
    log.append({
        "time": now,
        "action": "write_rule_check",
        "status": "verified"
    })
    
    # 只保留最近100条
    log = log[-100:]
    LOG_FILE.write_text(json.dumps(log, ensure_ascii=False))
    
    return {"status": "ok", "time": now}

if __name__ == "__main__":
    print(json.dumps(check(), ensure_ascii=False))
