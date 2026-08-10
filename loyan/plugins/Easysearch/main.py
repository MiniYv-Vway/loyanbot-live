import os
import urllib.parse
import sys
import socket
import secrets
from typing import Dict, Optional

os.environ.setdefault('LANG', 'zh_CN.UTF-8')
os.environ.setdefault('FONTCONFIG_PATH', '/etc/fonts')

from playwright.async_api import async_playwright, TimeoutError as PwTimeout
from graci import plugin_manager, loyan_send_msg, LoyanImage, LoyanText
from graci import get_logger; logger = get_logger("Easysearch")

PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))
CACHE_DIR = os.path.join(PLUGIN_DIR, "data")

IPHONE_VIEWPORT = {"width": 390, "height": 844}
IPHONE_UA = (
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
)
MAX_PAGE_HEIGHT = 4000

# 跨平台浏览器路径检测：Linux 系统 Chromium → Windows Playwright 内置
_CHROMIUM_PATHS = ["/usr/bin/chromium", "/usr/bin/chromium-browser", "/snap/bin/chromium"]
_CHROMIUM_PATH = next((p for p in _CHROMIUM_PATHS if os.path.exists(p)), None)

COMMON_PROXIES = [
    "http://127.0.0.1:7890",
    "http://127.0.0.1:10809",
    "http://127.0.0.1:1080",
    "http://127.0.0.1:7891",
    "http://127.0.0.1:8118",
]


def _load_config() -> dict:
    """从统一配置系统加载配置"""
    return plugin_manager.get_plugin_config("Easysearch") or {}


def _is_private_ip(host: str) -> bool:
    """判断主机是否为内网/回环地址（用于防 SSRF）"""
    try:
        addr_info = socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
    except socket.gaierror:
        return False
    for info in addr_info:
        ip = info[4][0]
        if ip.startswith("127.") or ip == "::1":
            return True
        if ip == "0.0.0.0":
            return True
        if ip.startswith("10.") or ip.startswith("192.168."):
            return True
        if ip.startswith("172."):
            try:
                second = int(ip.split(".")[1])
                if 16 <= second <= 31:
                    return True
            except (ValueError, IndexError):
                continue
        if ip.startswith("169.254."):
            return True
        if ip.lower().startswith("fe80"):
            return True
    return False


def _validate_browse_url(url: str) -> Optional[str]:
    """校验浏览 URL：必须 http/https 且非内网地址，返回错误信息或 None"""
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url
    try:
        parsed = urllib.parse.urlparse(url)
    except Exception:
        return "URL 格式错误"
    if parsed.scheme not in ("http", "https"):
        return "仅支持 http/https 链接"
    if not parsed.hostname:
        return "URL 缺少主机名"
    if _is_private_ip(parsed.hostname):
        return "不允许访问内网地址"
    return None


def _detect_proxy() -> Optional[Dict[str, str]]:
    # 1. config.json 优先
    cfg = _load_config()
    proxy_url = cfg.get("proxy", "")
    if proxy_url:
        return {"server": proxy_url}
    # 2. 环境变量
    for env_name in ("HTTPS_PROXY", "HTTP_PROXY", "https_proxy", "http_proxy", "ALL_PROXY"):
        val = os.environ.get(env_name, "")
        if val:
            return {"server": val}
    # 3. Windows 系统代理注册表
    if sys.platform == "win32":
        try:
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings")
            enabled, _ = winreg.QueryValueEx(key, "ProxyEnable")
            if enabled:
                server, _ = winreg.QueryValueEx(key, "ProxyServer")
                winreg.CloseKey(key)
                server = server.strip()
                if "=" in server:
                    server = server.split(";")[0].split("=")[-1].strip()
                if not server.startswith("http"):
                    server = "http://" + server
                return {"server": server}
            winreg.CloseKey(key)
        except Exception:
            pass
    return None


async def _screenshot_page(url: str, wait_ms: int = 3000) -> Optional[str]:
    cfg = _load_config()
    timeout = cfg.get("timeout", 20) * 1000
    proxy = _detect_proxy()
    if proxy:
        logger.info(f"[截图] 使用代理: {proxy['server']}")

    try:
        async with async_playwright() as pw:
            launch_args = {"headless": True, "args": ["--no-sandbox", "--disable-blink-features=AutomationControlled"]}
            if _CHROMIUM_PATH:
                launch_args["executable_path"] = _CHROMIUM_PATH
            if proxy:
                launch_args["proxy"] = proxy

            browser = await pw.chromium.launch(**launch_args)
            context = await browser.new_context(
                viewport=IPHONE_VIEWPORT,
                user_agent=IPHONE_UA,
                device_scale_factor=2,
                is_mobile=True,
                has_touch=True,
            )
            page = await context.new_page()
            logger.info(f"[截图] 正在导航至: {url[:60]}...")
            await page.goto(url, timeout=timeout, wait_until="networkidle")
            await page.wait_for_timeout(wait_ms)

            page_height = await page.evaluate("document.body.scrollHeight")
            page_height = min(page_height, MAX_PAGE_HEIGHT)

            path = os.path.join(CACHE_DIR, f"browser_screenshot_{secrets.token_hex(6)}.png")
            os.makedirs(CACHE_DIR, exist_ok=True)
            await page.screenshot(path=path, full_page=False, clip={
                "x": 0, "y": 0,
                "width": IPHONE_VIEWPORT["width"],
                "height": min(page_height, 3000),
            })
            logger.info(f"[截图] 成功: {path}")
            return path

    except PwTimeout:
        logger.warning(f"[截图] 超时: {url[:60]}...")
        return None
    except Exception as e:
        logger.error(f"[截图] 失败: {e}", exc_info=True)
        return None


SEARCH_URLS = {
    "bing": "https://www.bing.com/search?q={query}",
    "baidu": "https://www.baidu.com/s?wd={query}",
    "google": "https://www.google.com/search?q={query}&hl=zh-CN",
    "sogou": "https://www.sogou.com/web?query={query}",
    "yandex": "https://yandex.com/search/?text={query}",
}


async def do_search(query: str, engine: str = None) -> Dict:
    cfg = _load_config()
    if not engine:
        engine = cfg.get("default_engine", "baidu")
    if engine not in SEARCH_URLS:
        return {"ok": False, "error": f"不支持的搜索引擎: {engine}"}

    engine_cn = cfg.get("engines", {}).get(engine, {}).get("name", engine)
    url = SEARCH_URLS[engine].format(query=urllib.parse.quote(query))
    path = await _screenshot_page(url)
    if not path:
        return {"ok": False, "error": f"截图失败（{engine_cn}）\n请检查代理配置或网络连接"}
    return {"ok": True, "image_path": path, "engine": engine, "engine_cn": engine_cn, "query": query}


async def do_browse(url: str) -> Dict:
    err = _validate_browse_url(url)
    if err:
        return {"ok": False, "error": err}
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url
    path = await _screenshot_page(url)
    if not path:
        return {"ok": False, "error": f"无法访问或截图超时: {url}\n请检查代理配置或网络连接"}
    return {"ok": True, "image_path": path, "url": url}


ENGINE_ALIASES = {
    "/搜索": None, "搜索": None,
    "/必应搜索": "bing",
    "/百度搜索": "baidu",
    "/谷歌搜索": "google",
    "/搜狗搜索": "sogou",
    "/Yandex搜索": "yandex",
}


def _extract_search(raw_msg: str):
    for cmd, engine in ENGINE_ALIASES.items():
        if raw_msg == cmd:
            return engine, ""
        if raw_msg.startswith(cmd + " "):
            kw = raw_msg[len(cmd):].strip()
            return engine, kw
    return None, None


def _extract_browse(raw_msg: str):
    if raw_msg == "/浏览":
        return ""
    if raw_msg.startswith("/浏览 "):
        return raw_msg[4:].strip()
    return None


def _draw_error(msg: str) -> str:
    from .core.draw import draw_error
    return draw_error(msg)


async def handle_easysearch(self_bot, bot, message, user_id, chat_type, permission, log_func):
    """易搜助手入口（metadata entry）"""
    raw_msg = message.get("text", "").strip()
    target_id = str(message.get("raw_data", {}).get("group_id") if chat_type == "group" else user_id)

    engine, query = _extract_search(raw_msg)
    if query is not None:
        if not query:
            await loyan_send_msg(target_id, LoyanText(text="❌ 用法：/搜索 关键词\n或：/百度搜索 关键词 /必应搜索 关键词 /谷歌搜索 关键词 /搜狗搜索 关键词 /Yandex搜索 关键词"), chat_type=chat_type)
            return True
        await loyan_send_msg(target_id, LoyanText(text=f"🔍 正在搜索: {query}"), chat_type=chat_type)
        result = await do_search(query, engine)
        if result["ok"]:
            await loyan_send_msg(target_id, LoyanImage(file_path=result["image_path"]), chat_type=chat_type)
        else:
            img_path = _draw_error(result["error"])
            await loyan_send_msg(target_id, LoyanImage(file_path=img_path), chat_type=chat_type)
        log_func.info(f"用户{user_id} 搜索: {query} (引擎:{engine or '默认'})")
        return True

    browse_url = _extract_browse(raw_msg)
    if browse_url is not None:
        if not browse_url:
            await loyan_send_msg(target_id, LoyanText(text="❌ 用法：/浏览 https://example.com"), chat_type=chat_type)
            return True
        await loyan_send_msg(target_id, LoyanText(text="🌐 正在浏览..."), chat_type=chat_type)
        result = await do_browse(browse_url)
        if result["ok"]:
            await loyan_send_msg(target_id, LoyanImage(file_path=result["image_path"]), chat_type=chat_type)
        else:
            img_path = _draw_error(result["error"])
            await loyan_send_msg(target_id, LoyanImage(file_path=img_path), chat_type=chat_type)
        log_func.info(f"用户{user_id} 浏览: {browse_url}")
        return True

    return False




