"""
中文字体工具 — 自动安装 + 强制中文字体

提供:
    ensure_chinese_font()  -> bool   检测/安装中文字体
    get_zh_font(size)                强制返回中文字体（不回退默认位图字体）
    get_font_path()                  返回可用的中文字体文件路径

策略:
    1. 按优先级查找已安装的中文字体（框架自带 / 系统 Noto CJK / 文泉驿 / 本地缓存）
    2. 若缺失，先尝试 apt 安装 fonts-noto-cjk
    3. apt 失败则从可信 URL 下载字体到本地缓存目录
    4. 最终找不到时抛异常（强制中文字体，不允许用默认字体画中文）
"""
import os
import logging
import subprocess
from typing import List, Optional

logger = logging.getLogger("Loyan.zhfont")

_APT_PACKAGES = ["fonts-noto-cjk"]
_FONT_URLS = [
    "https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf",
    "https://raw.githubusercontent.com/googlefonts/noto-cjk/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf",
]

try:
    from loyan.core.tools.paths import get_storage_dir
except Exception:
    def get_storage_dir():
        return os.path.join(os.getcwd(), "storage")


_LOCAL_FONT_DIR = os.path.join(get_storage_dir(), "data", "fonts")
_LOCAL_FONT_NAME = "NotoSansCJKsc-Regular.otf"
_LOCAL_FONT_PATH = os.path.join(_LOCAL_FONT_DIR, _LOCAL_FONT_NAME)

# 候选字体文件（按优先级）
def _candidate_paths() -> List[str]:
    try:
        from loyan.core.tools.paths import get_res_dir
        res = get_res_dir()
    except Exception:
        res = os.path.join(os.getcwd(), "loyan", "res", "resource")

    candidates = [
        os.path.join(res, "DouyinSansBold.otf"),
        os.path.join(os.getcwd(), "style", "resource", "DouyinSansBold.otf"),
        # 系统 CJK 字体
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
        "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
        "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
        "/usr/share/fonts/truetype/wqy/wqy-microhei.ttf",
        "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttf",
        "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttf",
        _LOCAL_FONT_PATH,
    ]
    return candidates


def _find_existing_font() -> Optional[str]:
    """返回第一个存在的中文字体路径，不存在返回 None"""
    for path in _candidate_paths():
        if path and os.path.isfile(path):
            return path
    return None


def _apt_install() -> bool:
    """尝试通过 apt 安装中文字体，成功返回 True"""
    if not os.geteuid() == 0:
        return False
    try:
        subprocess.run(
            ["apt-get", "update", "-qq"],
            capture_output=True, timeout=60,
        )
        result = subprocess.run(
            ["apt-get", "install", "-y", "-qq", * _APT_PACKAGES],
            capture_output=True, timeout=300,
        )
        if result.returncode == 0:
            return _find_existing_font() is not None
        logger.warning("apt 安装中文字体失败: %s", result.stderr.decode('utf-8', 'replace')[-500:])
    except Exception as e:
        logger.warning("apt 安装中文字体异常: %s", e)
    return False


def _download_font() -> bool:
    """尝试从可信 URL 下载中文字体到本地缓存目录"""
    os.makedirs(_LOCAL_FONT_DIR, exist_ok=True)
    for url in _FONT_URLS:
        try:
            import urllib.request
            import socket
            socket.setdefaulttimeout(60)
            logger.info("正在下载中文字体: %s", url)
            urllib.request.urlretrieve(url, _LOCAL_FONT_PATH + ".part")
            os.replace(_LOCAL_FONT_PATH + ".part", _LOCAL_FONT_PATH)
            if os.path.isfile(_LOCAL_FONT_PATH):
                logger.info("中文字体下载完成: %s", _LOCAL_FONT_PATH)
                return True
        except Exception as e:
            logger.warning("字体下载失败 %s: %s", url, e)
    return False


_checked = False


def ensure_chinese_font() -> bool:
    """确保系统中存在可用中文字体，返回是否可用"""
    global _checked
    if _checked:
        return _find_existing_font() is not None

    if _find_existing_font():
        _checked = True
        return True

    logger.warning("未检测到中文字体，尝试自动安装...")
    if _apt_install():
        _checked = True
        return True

    if _download_font():
        _checked = True
        return True

    logger.error("中文字体自动安装失败")
    return False


def get_font_path() -> str:
    """返回可用中文字体路径；无可用中文字体时抛出异常"""
    if _find_existing_font():
        return _find_existing_font()
    if ensure_chinese_font():
        return _find_existing_font()
    raise RuntimeError("系统缺少中文字体且自动安装失败，无法绘制中文")


def get_zh_font(size: int):
    """强制返回中文字体（ImageFont），不回落默认位图字体"""
    from PIL import ImageFont
    path = get_font_path()
    try:
        return ImageFont.truetype(path, size)
    except Exception as e:
        logger.warning("加载字体 %s 失败(%s)，尝试直接路径", path, e)
        raise RuntimeError(f"中文字体加载失败: {e}") from e
