#!/usr/bin/env python3
"""
防休眠守护 v4.0 - 守护机器人和五子棋服务
"""
import os, sys, time, signal, subprocess, logging, urllib.request, socket
from pathlib import Path

BASE = Path("/root/loyanbot")
LOG_DIR = BASE / "storage" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [%(name)s] - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "keeper.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("Keeper")

BOT_PID_FILE = LOG_DIR / "bot.pid"
KEEPER_PID_FILE = LOG_DIR / "keeper.pid"
SERVER_PID_FILE = LOG_DIR / "server.pid"
GOBANG_DIR = Path("/root/gobang")
GOBANG_PORT = 12345


def is_pid_alive(pid):
    """检查进程是否存活且非僵尸"""
    try:
        os.kill(pid, 0)
        with open(f"/proc/{pid}/stat") as f:
            return f.read().split()[2] != "Z"
    except (ProcessLookupError, FileNotFoundError):
        return False


def is_port_listening(port, host='127.0.0.1'):
    """检查端口是否在监听"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex((host, port)) == 0


def start_bot():
    log.info("启动 bot...")
    env = os.environ.copy()
    env["PYTHONPATH"] = str(BASE)
    try:
        proc = subprocess.Popen(
            [sys.executable, str(BASE / "bot.py")],
            env=env, cwd=str(BASE),
            stdout=open(LOG_DIR / "bot_daemon.log", "a", buffering=1),
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        BOT_PID_FILE.write_text(str(proc.pid))
        log.info(f"bot 已启动 PID={proc.pid}")
        return True
    except Exception as e:
        log.error(f"启动 bot 失败: {e}")
        return False


def load_env_file(env_file):
    """从 .env 文件加载环境变量（忽略空行和注释行）"""
    env = os.environ.copy()
    try:
        for line in Path(env_file).read_text().splitlines():
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, _, v = line.partition('=')
            env[k.strip()] = v.strip()
    except Exception as e:
        log.error(f"加载环境变量文件 {env_file} 失败: {e}")
    return env


def start_server():
    log.info("启动五子棋服务...")
    try:
        env = load_env_file(GOBANG_DIR / ".env")
        proc = subprocess.Popen(
            ["node", str(GOBANG_DIR / "server.js")],
            env=env,
            stdout=open(LOG_DIR / "server_daemon.log", "a", buffering=1),
            stderr=subprocess.STDOUT,
            cwd=str(GOBANG_DIR),
            start_new_session=True,
        )
        SERVER_PID_FILE.write_text(str(proc.pid))
        log.info(f"五子棋服务 已启动 PID={proc.pid}")
        return True
    except Exception as e:
        log.error(f"启动五子棋服务 失败: {e}")
        return False


def check_and_restart_bot():
    pid = None
    if BOT_PID_FILE.exists():
        try:
            pid = int(BOT_PID_FILE.read_text().strip())
        except:
            pass

    if pid and is_pid_alive(pid):
        log.debug(f"bot 运行中 PID={pid}")
        return True

    if pid:
        log.info(f"bot (PID={pid}) 已停止，重启...")
        BOT_PID_FILE.unlink(missing_ok=True)

    return start_bot()


def check_and_restart_server():
    pid = None
    if SERVER_PID_FILE.exists():
        try:
            pid = int(SERVER_PID_FILE.read_text().strip())
        except:
            pass

    # 检查端口是否在监听（更可靠）
    if is_port_listening(GOBANG_PORT, '127.0.0.1'):
        log.debug(f"五子棋服务 端口 {GOBANG_PORT} 正常监听")
        return True

    if pid:
        log.info(f"五子棋服务 (PID={pid}) 已停止，重启...")
        SERVER_PID_FILE.unlink(missing_ok=True)

    return start_server()


def monitor():
    while True:
        check_and_restart_bot()
        check_and_restart_server()
        time.sleep(30)


def main():
    KEEPER_PID_FILE.write_text(str(os.getpid()))
    log.info("Keeper v4.0 启动 - 守护 bot 和 五子棋服务")

    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))

    # 先检查再启动，避免与既有实例重复（端口已监听时 spawn node 会立即失败变僵尸，bot 会重复启动）
    check_and_restart_bot()
    check_and_restart_server()

    # 开始监控
    monitor()


if __name__ == "__main__":
    main()
