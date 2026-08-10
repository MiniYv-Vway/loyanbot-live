"""帮助插件 — 查询所有插件命令，返回帮助图片"""
import collections
import os
from graci import get_logger, on_command, plugin_handler, PluginContext
from graci import LoyanImage
from graci import plugin_manager, config_manager
from .core.draw import LoyanBotHelpDrawer

logger = get_logger("Help")

config_manager.register_plugin_config("帮助插件")

_drawer = None


def _get_drawer():
    global _drawer
    if _drawer is None:
        config = config_manager.get_plugin("帮助插件")
        if not isinstance(config, dict):
            config = {}
        _drawer = LoyanBotHelpDrawer(config)
    return _drawer


@on_command("/help", "/帮助", "/菜单", "/helps")
@plugin_handler
async def handle_help(ctx: PluginContext):
    """生成帮助图片并发送"""
    # 收集所有插件命令
    from graci import plugin_manager
    plugin_commands = collections.defaultdict(list)
    for plugin in plugin_manager.registry:
        name = plugin.get("name", "未知插件")
        if name == "帮助插件":
            continue
        if name == "游戏插件":
            plugin_commands["游戏专区"] = ["/game#🎮 游戏指令大全（钓鱼/挖矿/打猎/签到等）"]
            continue
        if name in ("王者荣耀热点", "和平精英热点", "逃跑吧少年"):
            # 游戏热点插件：只显示主命令，隐藏翻页/别名
            main_cmds = ["/王者热点#🔥 王者荣耀热点", "/王者爆料#⚡ 版本/皮肤爆料", "/王者攻略#📖 攻略（可加英雄名）",
                         "/和平热点#🔫 和平精英热点", "/和平爆料#⚡ 版本/活动爆料", "/和平攻略#📖 攻略（可加关键词）",
                         "/逃跑热点#🔥 逃跑吧少年热点", "/逃跑爆料#⚡ 版本/活动爆料", "/逃跑攻略#📖 攻略",
                         "/逃跑兑换码#🎁 通用兑换码"]
            if name == "王者荣耀热点":
                plugin_commands["游戏热点"] = list(main_cmds[:3])
            elif name == "和平精英热点":
                plugin_commands["游戏热点"].extend(main_cmds[3:6])
            else:
                plugin_commands["游戏热点"].extend(main_cmds[6:])
            continue
        desc = plugin.get("description", "")
        cmd_descs = plugin.get("command_descriptions", {})
        for cmd in plugin.get("commands", []):
            cmd_desc = cmd_descs.get(cmd, "") or desc
            plugin_commands[name].append(f"{cmd}#{cmd_desc}" if cmd_desc else cmd)

    if not plugin_commands:
        await ctx.reply("没有找到任何插件或命令")
        return

    try:
        image = _get_drawer().draw_help_image(dict(plugin_commands))
        temp_dir = os.path.join(os.path.dirname(__file__), "data")
        os.makedirs(temp_dir, exist_ok=True)
        import secrets
        temp_path = os.path.join(temp_dir, f"temp_help_{secrets.token_hex(6)}.png")
        with open(temp_path, "wb") as f:
            f.write(image)
        await ctx.send(LoyanImage(file_path=temp_path))
    except Exception as e:
        logger.error(f"生成帮助图片失败: {e}")
        await ctx.reply("生成帮助图片失败，请联系管理员")
