"""
群聊注册表 — 记录群聊活跃信息（供 MasterControl 等插件使用）

数据保存在 <项目根>/data/group_registry.json

提供:
    get_all_groups() -> List[Dict]    所有群记录
    get_group(group_id) -> Dict|None  单个群记录
    set_group_name(group_id, name)    设置群备注名（持久化）
"""
import json
import os
from typing import Dict, List, Optional

from loyan.core.tools.paths import get_project_root

_registry_path = os.path.join(get_project_root(), "data", "group_registry.json")


def _load() -> Dict[str, Dict]:
    try:
        with open(_registry_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {}


def _save(data: Dict[str, Dict]) -> None:
    try:
        os.makedirs(os.path.dirname(_registry_path), exist_ok=True)
        tmp = _registry_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.replace(tmp, _registry_path)
    except Exception:
        pass


def get_all_groups() -> List[Dict]:
    return list(_load().values())


def get_group(group_id: str) -> Optional[Dict]:
    if not group_id:
        return None
    return _load().get(str(group_id))


def set_group_name(group_id: str, name: str) -> None:
    data = _load()
    key = str(group_id)
    if key not in data:
        data[key] = {
            "group_id": key,
            "group_name": name or f"群_{key[:8]}",
            "message_count": 0,
        }
    data[key]["group_name"] = name or f"群_{key[:8]}"
    _save(data)
