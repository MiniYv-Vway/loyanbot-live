import os
import sys
import subprocess
import functools

from graci import get_logger; logger = get_logger("Screenshot")
PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))
STATE_FILE = os.path.join(PLUGIN_DIR, ".dep_checked")


def _ensure_deps():
    """首次使用时检查并安装依赖；失败时记录缺失项供后续重试"""
    try:
        missing = []
        try:
            import mss
        except ImportError:
            missing.append("mss")
        try:
            from PIL import Image
        except ImportError:
            missing.append("Pillow")

        if missing:
            logger.info("Installing dependencies: %s", ", ".join(missing))
            failed = []
            for pkg in missing:
                try:
                    result = subprocess.run(
                        [sys.executable, "-m", "pip", "install", pkg],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        timeout=120,
                    )
                    if result.returncode != 0:
                        failed.append(pkg)
                except Exception as e:
                    logger.error("pip install %s failed: %s", pkg, e)
                    failed.append(pkg)
            if failed:
                logger.error("Dependencies failed to install: %s", ", ".join(failed))
                return False

        # 仅全部成功后才写标记
        try:
            with open(STATE_FILE, "w") as f:
                f.write("1")
        except OSError:
            pass
        return True
    except Exception as e:
        logger.error("Dependency check error: %s", e)
        return False


from .main import handle_screenshot as _handle_screenshot


@functools.lru_cache(maxsize=1)
def _init_deps():
    return _ensure_deps()


async def handle_screenshot(*args, **kwargs):
    _init_deps()
    return await _handle_screenshot(*args, **kwargs)


export_dict = {
    "handle_screenshot": handle_screenshot
}
