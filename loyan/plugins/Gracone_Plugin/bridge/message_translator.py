"""消息段翻译器 — LoyanMsg ↔ OneBot V11 Message/MessageSegment 双向转换"""

from typing import Any, List, Optional, Union

from graci import LoyanText, LoyanImage, LoyanVoice, LoyanMsg, LoyanAt, LoyanReply, LoyanFile


def gracy_to_nb_segment(msg: LoyanMsg) -> Any:
    """将 LoyanMsg 转换为 OneBot V11 MessageSegment
    
    Args:
        msg: 任意 LoyanMsg 子类实例
        
    Returns:
        OneBot V11 MessageSegment 实例
    """
    # 延迟导入避免循环依赖
    from gracone_nonebot import MessageSegment
    
    if isinstance(msg, LoyanText):
        return MessageSegment.text(msg.text)
    elif isinstance(msg, LoyanImage):
        url = getattr(msg, 'url', '') or ''
        file_path = getattr(msg, 'file_path', '') or ''
        file_data = getattr(msg, 'file_data', b'') or b''
        if file_path:
            return MessageSegment.image(file=file_path, url=url)
        elif url:
            return MessageSegment.image(file=url, url=url)
        elif file_data:
            import base64
            b64 = base64.b64encode(file_data).decode()
            return MessageSegment.image(file=f"base64://{b64}")
        return MessageSegment.image(file="")
    elif isinstance(msg, LoyanAt):
        return MessageSegment.at(str(msg.target_id))
    elif isinstance(msg, LoyanReply):
        return MessageSegment.reply(str(msg.message_id))
    elif isinstance(msg, LoyanVoice):
        path = getattr(msg, 'file_path', '') or getattr(msg, 'url', '') or ''
        return MessageSegment.record(file=path)
    elif isinstance(msg, LoyanFile):
        path = getattr(msg, 'file_path', '') or getattr(msg, 'url', '') or ''
        return MessageSegment.file(file=path)
    else:
        # 未知类型，降级为 text
        return MessageSegment.text(str(msg))


def gracy_to_nb_message(segments: List[LoyanMsg]) -> Any:
    """将 LoyanMsg 列表转换为 OneBot V11 Message
    
    Args:
        segments: LoyanMsg 列表
        
    Returns:
        OneBot V11 Message 实例
    """
    from gracone_nonebot import Message
    msg = Message()
    for seg in segments:
        msg.append(gracy_to_nb_segment(seg))
    return msg


def nb_to_gracy_segment(seg: Any) -> LoyanMsg:
    """将 OneBot V11 MessageSegment 转换为 LoyanMsg
    
    Args:
        seg: OneBot V11 MessageSegment 实例
        
    Returns:
        对应的 LoyanMsg 子类实例
    """
    seg_type = getattr(seg, 'type', '')
    data = getattr(seg, 'data', {}) or {}
    
    if seg_type == 'text':
        return LoyanText(text=str(data.get('text', '')))
    elif seg_type == 'image':
        url = str(data.get('url', '') or '')
        file_path = str(data.get('file', '') or '')
        if url:
            return LoyanImage(url=url)
        return LoyanImage(file_path=file_path)
    elif seg_type == 'at':
        return LoyanAt(target_id=str(data.get('qq', '')))
    elif seg_type == 'reply':
        return LoyanReply(message_id=str(data.get('id', '')))
    elif seg_type == 'record':
        path = str(data.get('file', '') or data.get('url', '') or '')
        return LoyanVoice(file_path=path)
    elif seg_type == 'file':
        path = str(data.get('file', '') or data.get('url', '') or '')
        return LoyanFile(file_path=path)
    else:
        # 降级：把未知段类型序列化为 text
        return LoyanText(text=str(seg))


def nb_to_gracy_segments(nb_message: Any) -> List[LoyanMsg]:
    """将 OneBot V11 Message 转换为 LoyanMsg 列表
    
    Args:
        nb_message: OneBot V11 Message 实例（或类似容器的可迭代对象）
        
    Returns:
        LoyanMsg 列表
    """
    segments = []
    for seg in nb_message:
        segments.append(nb_to_gracy_segment(seg))
    return segments


def nb_message_to_plain_text(nb_message: Any) -> str:
    """从 OneBot Message 中提取纯文本
    
    Args:
        nb_message: OneBot Message 实例
        
    Returns:
        纯文本字符串
    """
    if hasattr(nb_message, 'extract_plain_text'):
        return nb_message.extract_plain_text()
    parts = []
    for seg in nb_message:
        if getattr(seg, 'type', '') == 'text':
            parts.append(str(seg.data.get('text', '')))
    return ''.join(parts).strip()
