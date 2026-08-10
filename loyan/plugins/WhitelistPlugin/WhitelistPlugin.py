import json
import logging
import os
import tempfile
from datetime import datetime

from loyan.core.decorators import on_command, plugin_handler, PluginContext
from loyan.core.decorators.registration import on_fallback
from graci import LoyanText
from graci import loyan_send_msg
from loyan.core.pipeline.helpers import is_master

_logger = logging.getLogger("Gracy.白名单")

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(DATA_DIR, "whitelist.json")

# 允许非白名单用户使用的命令（申请白名单相关）
_PUBLIC_COMMANDS = ("/申请", "/apply", "/whitelist", "/approve", "/reject",
                    "/addwhitelist", "/removewhitelist")


def _load() -> dict:
    """加载白名单数据，文件损坏时安全降级"""
    try:
        if not os.path.exists(DATA_FILE):
            return {}
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {}
        return data
    except (json.JSONDecodeError, OSError, ValueError) as e:
        _logger.warning("白名单数据文件读取失败，按空数据处理: %s", e)
        return {}


def _save(data: dict) -> None:
    """原子化保存白名单数据，避免写一半损坏"""
    try:
        os.makedirs(DATA_DIR, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(dir=DATA_DIR, suffix=".tmp")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp_path, DATA_FILE)
        except Exception:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            raise
    except Exception as e:
        _logger.error("白名单数据保存失败: %s", e)


def is_whitelisted(user_id) -> bool:
    """判断用户是否在白名单中（公共函数，供其他插件/安全层调用）"""
    data = _load()
    uid = str(user_id)
    entry = data.get(uid)
    return bool(entry and entry.get("status") == "approved")


def _is_master_sender(user_id) -> bool:
    """判断是否为机器人主人"""
    try:
        from loyan.core.config import get_current_master_id
        master_id = get_current_master_id()
        if master_id and str(user_id) == str(master_id):
            return True
    except Exception:
        pass
    try:
        from loyan.core.config import MASTER_ID
        if MASTER_ID and str(user_id) == str(MASTER_ID):
            return True
    except Exception:
        pass
    return False


def _is_public_command(text: str) -> bool:
    stripped = (text or "").strip()
    for cmd in _PUBLIC_COMMANDS:
        if stripped == cmd or stripped.startswith(cmd + " "):
            return True
    return False


@on_fallback()
async def handle_block(self_bot, bot, message, user_id, chat_type, permission, logger):
    """兜底拦截：非白名单用户除了 /申请 相关命令外不得使用机器人"""
    sender_id = str(user_id)
    if _is_master_sender(sender_id):
        return
    if is_whitelisted(sender_id):
        return
    text = message.get("text", "") if isinstance(message, dict) else str(message or "")
    if _is_public_command(text):
        return
    _logger.info("白名单拦截: 非白名单用户 %s 的消息被阻止", sender_id)
    await bot(sender_id, LoyanText("⛔ 你不在白名单中，无法使用本机器人。\n请发送 /申请 提交白名单申请。"), chat_type=chat_type)
    return None


@on_command("/申请", "/apply")
@plugin_handler
async def handle_apply(ctx: PluginContext):
    data = _load()
    uid = str(ctx.sender_id)
    if uid in data:
        status = data[uid].get("status", "")
        if status == "approved":
            await ctx.reply("你已在白名单中，无需重复申请")
        elif status == "pending":
            await ctx.reply("你的申请正在审核中，请耐心等待")
        elif status == "rejected":
            await ctx.reply("你的申请已被拒绝")
        return

    data[uid] = {
        "nickname": ctx.nickname or uid,
        "status": "pending",
        "applied_at": datetime.now().isoformat(),
        "approved_at": None
    }
    _save(data)
    _logger.info(f"新白名单申请: {uid} ({ctx.nickname})")
    await ctx.reply("申请已提交，请等待管理员审核")


@on_command("/whitelist")
@plugin_handler
async def handle_whitelist(ctx: PluginContext):
    if not is_master(ctx):
        await ctx.reply("无权操作")
        return

    data = _load()
    if not data:
        await ctx.reply("白名单为空")
        return

    pending = []
    approved = []
    rejected = []
    for uid, info in data.items():
        nickname = info.get("nickname", uid)
        applied = info.get("applied_at", "")[:10]
        entry = f"{uid} ({nickname}) - {applied}"
        if info.get("status") == "pending":
            pending.append(entry)
        elif info.get("status") == "approved":
            approved.append(entry)
        else:
            rejected.append(entry)

    lines = []
    if pending:
        lines.append("--- 待审核 ---")
        lines.extend(pending)
    if approved:
        lines.append("--- 已通过 ---")
        lines.extend(approved)
    if rejected:
        lines.append("--- 已拒绝 ---")
        lines.extend(rejected)

    await ctx.reply("\n".join(lines) if lines else "白名单为空")


@on_command("/approve")
@plugin_handler
async def handle_approve(ctx: PluginContext):
    if not is_master(ctx):
        await ctx.reply("无权操作")
        return

    parts = ctx.raw_text.split(None, 2)
    if len(parts) < 2:
        await ctx.reply("用法: /approve <用户ID>")
        return

    uid = parts[1]
    data = _load()
    if uid not in data:
        await ctx.reply(f"未找到用户 {uid} 的申请记录")
        return
    if data[uid].get("status") == "approved":
        await ctx.reply(f"用户 {uid} 已在白名单中")
        return

    data[uid]["status"] = "approved"
    data[uid]["approved_at"] = datetime.now().isoformat()
    _save(data)
    _logger.info(f"白名单通过: {uid}")
    await ctx.reply(f"已通过用户 {uid} 的白名单申请")
    await loyan_send_msg(uid, LoyanText("你的白名单申请已通过，现在可以使用全部功能了"), chat_type="private", tag=ctx.adapter_tag)


@on_command("/reject")
@plugin_handler
async def handle_reject(ctx: PluginContext):
    if not is_master(ctx):
        await ctx.reply("无权操作")
        return

    parts = ctx.raw_text.split(None, 2)
    if len(parts) < 2:
        await ctx.reply("用法: /reject <用户ID>")
        return

    uid = parts[1]
    data = _load()
    if uid not in data:
        await ctx.reply(f"未找到用户 {uid} 的申请记录")
        return
    if data[uid].get("status") == "rejected":
        await ctx.reply(f"用户 {uid} 已被拒绝")
        return

    data[uid]["status"] = "rejected"
    _save(data)
    _logger.info(f"白名单拒绝: {uid}")
    await ctx.reply(f"已拒绝用户 {uid} 的白名单申请")
    await loyan_send_msg(uid, LoyanText("你的白名单申请已被拒绝"), chat_type="private", tag=ctx.adapter_tag)


@on_command("/addwhitelist")
@plugin_handler
async def handle_addwhitelist(ctx: PluginContext):
    if not is_master(ctx):
        await ctx.reply("无权操作")
        return

    parts = ctx.raw_text.split(None, 2)
    if len(parts) < 2:
        await ctx.reply("用法: /addwhitelist <用户ID>")
        return

    uid = parts[1]
    data = _load()
    if uid in data and data[uid].get("status") == "approved":
        await ctx.reply(f"用户 {uid} 已在白名单中")
        return

    nickname = parts[2] if len(parts) > 2 else uid
    data[uid] = {
        "nickname": nickname,
        "status": "approved",
        "applied_at": datetime.now().isoformat(),
        "approved_at": datetime.now().isoformat()
    }
    _save(data)
    _logger.info(f"管理员直接添加白名单: {uid} ({nickname})")
    await ctx.reply(f"已添加用户 {uid} ({nickname}) 到白名单")
    await loyan_send_msg(uid, LoyanText("你已被管理员添加到白名单"), chat_type="private", tag=ctx.adapter_tag)


@on_command("/removewhitelist")
@plugin_handler
async def handle_removewhitelist(ctx: PluginContext):
    if not is_master(ctx):
        await ctx.reply("无权操作")
        return

    parts = ctx.raw_text.split(None, 2)
    if len(parts) < 2:
        await ctx.reply("用法: /removewhitelist <用户ID>")
        return

    uid = parts[1]
    data = _load()
    if uid not in data:
        await ctx.reply(f"未找到用户 {uid}")
        return

    del data[uid]
    _save(data)
    _logger.info(f"管理员移除白名单: {uid}")
    await ctx.reply(f"已移除用户 {uid} 的白名单")
