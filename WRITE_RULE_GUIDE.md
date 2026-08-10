# 写入规则强制机制使用说明

## 机制概述
- 关键文件默认使用 `chattr +i` 锁定，即使root也无法直接写入
- 写入前必须先创建待确认请求
- 用户确认后，文件解锁，允许写入
- 写入完成后，文件立即重新锁定

## 相关文件
- `/usr/local/bin/write_lock.sh` - 锁定管理器
- `/usr/local/bin/write_request_with_lock.sh` - 写入请求脚本
- `/usr/local/bin/write_confirm_and_unlock.sh` - 确认解锁脚本
- `/usr/local/bin/pre_write_check.sh` - 写入前检查脚本
- `/root/loyanbot/fs_monitor.py` - 文件系统监控
- `/root/loyanbot/auto_lock.sh` - 自动锁定（每分钟执行）
- `/root/loyanbot/violation_log.json` - 违规记录

## 使用流程

### 1. 写入前检查
```bash
pre_write_check.sh
```

### 2. 创建写入请求
```bash
write_request_with_lock.sh edit "/workspace/.monkeycode/MEMORY.md" "内容"
```

### 3. 用户确认
用户说"同意执行"或"确认执行"

### 4. 执行解锁
```bash
write_confirm_and_unlock.sh
```

### 5. 执行写入（现在文件已解锁）
使用Write/Edit工具写入文件

### 6. 重新锁定
```bash
write_lock.sh lock
```

## 查看状态
```bash
write_lock.sh status
/root/loyanbot/check_violations.sh
```

## 违规记录
违规记录保存在 `/root/loyanbot/violation_log.json`，会累积所有违规行为。
