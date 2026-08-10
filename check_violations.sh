#!/bin/bash
echo "=== 写入规则违规记录 ==="
echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

if [ -f /root/loyanbot/violation_log.json ]; then
    python3 -c "
import json
log = json.load(open('/root/loyanbot/violation_log.json'))
print(f'总违规次数: {log[\"total_violations\"]}')
print(f'最近违规: {log[\"last_violation\"] or \"无\"}')
print()
if log['violations']:
    print('最近违规记录:')
    for v in log['violations'][-5:]:
        print(f'  [{v[\"count\"]}] {v[\"time\"]}: {v[\"detail\"]}')
else:
    print('暂无违规记录')
"
else
    echo "无违规记录文件"
fi
