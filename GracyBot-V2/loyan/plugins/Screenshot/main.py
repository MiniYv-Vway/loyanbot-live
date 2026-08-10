import os
import shutil
import asyncio

from graci import get_current_master_id
from graci import loyan_send_msg
from graci import LoyanImage, LoyanText
from graci import get_logger; logger = get_logger("Screenshot")

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "image")
SAVE_DIR = os.path.join(DATA_DIR, "saved")

_latest_screenshot = None


async def handle_screenshot(self_bot, bot, message, user_id, chat_type, permission, log_func):
    global _latest_screenshot
    raw_msg = message.get("text", "").strip()
    target_id = str(message.get("raw_data", {}).get("group_id") if chat_type == "group" else user_id)

    if str(user_id) != str(get_current_master_id()):
        await loyan_send_msg(target_id, LoyanText(text="Permission denied."), chat_type=chat_type)
        return True

    if raw_msg == "/屏幕截图":
        from .capture import capture_screen
        try:
            path = await asyncio.to_thread(capture_screen)
            _latest_screenshot = path
            await loyan_send_msg(target_id, LoyanImage(file_path=path), chat_type=chat_type)
            await loyan_send_msg(target_id, LoyanText(text="Save this screenshot? Reply /保存截图"), chat_type=chat_type)
            logger.info("Captured: %s", os.path.basename(path))
        except Exception as e:
            logger.error("Capture failed: %s", str(e))
            await loyan_send_msg(target_id, LoyanText(text="Screenshot capture failed."), chat_type=chat_type)
        return True

    if raw_msg == "/保存截图":
        if not _latest_screenshot or not os.path.exists(_latest_screenshot):
            await loyan_send_msg(target_id, LoyanText(text="No screenshot to save."), chat_type=chat_type)
            return True
        try:
            os.makedirs(SAVE_DIR, exist_ok=True)
            filename = os.path.basename(_latest_screenshot)
            dest = os.path.join(SAVE_DIR, filename)
            shutil.copy2(_latest_screenshot, dest)
            logger.info("Saved: %s", dest)
            await loyan_send_msg(target_id, LoyanText(text="Screenshot saved to data/image/saved/."), chat_type=chat_type)
        except Exception as e:
            logger.error("Save failed: %s", str(e))
            await loyan_send_msg(target_id, LoyanText(text="Save failed."), chat_type=chat_type)
        return True

    return False
