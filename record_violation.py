#!/usr/bin/env python3
"""记录违规行为 - 外部强制"""
import json
import datetime
import sys
from pathlib import Path

LOG_FILE = Path("/root/loyanbot/violation_log.json")

def record_violation(detail=""):
    now = datetime.datetime.now().isoformat()
    
    log = {"violations": [], "total_violations": 0, "last_violation": None}
    if LOG_FILE.exists():
        try:
            log = json.loads(LOG_FILE.read_text())
        except:
            pass
    
    violation = {
        "time": now,
        "detail": detail,
        "count": log["total_violations"] + 1
    }
    
    log["violations"].append(violation)
    log["total_violations"] += 1
    log["last_violation"] = now
    
    # 只保留最近50条
    log["violations"] = log["violations"][-50:]
    
    LOG_FILE.write_text(json.dumps(log, ensure_ascii=False, indent=2))
    
    return log

if __name__ == "__main__":
    detail = sys.argv[1] if len(sys.argv) > 1 else "未说明原因"
    result = record_violation(detail)
    print(json.dumps({
        "status": "recorded",
        "total": result["total_violations"],
        "last": result["violations"][-1]
    }, ensure_ascii=False, indent=2))
