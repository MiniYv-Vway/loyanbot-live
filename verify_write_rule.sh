#!/bin/bash
# 每次对话前验证写入规则是否被读取
RULES_FILE="/root/loyanbot/write_rule_verified.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ ! -f "$RULES_FILE" ] || [ $(find "$RULES_FILE" -mmin -60 2>/dev/null) ]; then
    echo "[$TIMESTAMP] 写入规则验证通过" >> "$RULES_FILE"
    exit 0
else
    echo "警告：未检测到写入规则验证"
    exit 1
fi
