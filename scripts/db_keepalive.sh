#!/bin/bash
# 数据库活跃脚本 - 定期数据库操作保持数据库活跃
# 策略：每8秒执行一次数据库操作

LOG_DIR="/root/loyanbot/storage/logs"
LOG_FILE="$LOG_DIR/db_keepalive.log"
PID_FILE="$LOG_DIR/db_keepalive.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 数据库活动
db_activity() {
    # SQLite操作
    python3 -c "
import sqlite3
import os
import tempfile

# 创建临时数据库
db_path = tempfile.mktemp(suffix='.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 创建表
cursor.execute('CREATE TABLE IF NOT EXISTS keepalive (id INTEGER PRIMARY KEY, timestamp REAL, data TEXT)')

# 插入数据
import time
cursor.execute('INSERT INTO keepalive (timestamp, data) VALUES (?, ?)', (time.time(), 'keepalive'))

# 查询数据
cursor.execute('SELECT * FROM keepalive')
rows = cursor.fetchall()

# 更新数据
cursor.execute('UPDATE keepalive SET data = ? WHERE id = ?', ('updated', rows[0][0]))

# 删除数据
cursor.execute('DELETE FROM keepalive')

# 提交并关闭
conn.commit()
conn.close()

# 删除临时数据库
os.remove(db_path)

print('数据库活动完成')
" > /dev/null 2>&1
}

# 写入PID文件
echo $$ > "$PID_FILE"
log "数据库活跃脚本启动 PID=$$"

# 主循环
while true; do
    db_activity
    log "数据库活动完成"
    sleep 8
done
