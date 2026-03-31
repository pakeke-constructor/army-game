"""
TCP client for communicating with the Love2D agent bridge.
The game exposes a JSON-over-TCP socket when launched with --devport=PORT.
"""
import socket
import json
import time
import subprocess
import os
import threading
import collections
from dataclasses import dataclass, field


def _find_free_port():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


class GameCrashed(RuntimeError):
    """Raised when the game sends a crash notification."""
    pass


class GameClient:
    """Connects to the running Love2D game's agent bridge."""

    def __init__(self, host="127.0.0.1", port=27015, timeout=5.0):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(timeout)
        self.sock.connect((host, port))
        self._buf = b""
        self._id = 0

    def send(self, cmd, **kwargs):
        self._id += 1
        msg = {"cmd": cmd, "id": self._id, **kwargs}
        raw = json.dumps(msg) + "\n"
        self.sock.sendall(raw.encode())
        return self._recv()

    def _recv(self):
        while b"\n" not in self._buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ConnectionError("connection closed")
            self._buf += chunk
        line, self._buf = self._buf.split(b"\n", 1)
        resp = json.loads(line)
        # Crash notification from the game
        if "crash" in resp:
            raise GameCrashed(resp["crash"])
        resp.pop("id", None)
        resp.pop("cmd", None)
        if len(resp) == 1:
            return next(iter(resp.values()))
        return resp

    def close(self):
        self.sock.close()


# -------------------------------------------------------
# Game state
# -------------------------------------------------------

@dataclass
class GameState:
    process: subprocess.Popen | None = None
    client: GameClient | None = None
    crash_info: str | None = None
    stdout_buf: collections.deque = field(default_factory=lambda: collections.deque(maxlen=2000))


# -------------------------------------------------------
# Helpers
# -------------------------------------------------------

def _drain_pipe(pipe, buf):
    try:
        for line in iter(pipe.readline, ''):
            buf.append(line.rstrip('\n'))
        pipe.close()
    except Exception:
        pass


def _find_love_exe():
    for name in ["lovec.exe", "love.exe"]:
        for d in [r"C:\Program Files\LOVE", r"C:\Program Files (x86)\LOVE"]:
            c = os.path.join(d, name)
            if os.path.isfile(c):
                return c
    return "love"


# -------------------------------------------------------
# State-based API
# -------------------------------------------------------

def start_game(gs: GameState, port=None) -> GameClient:
    """Launch the Love2D game and connect. Mutates gs. Returns a GameClient."""
    if gs.client:
        try:
            gs.client.send("ping")
            return gs.client
        except Exception:
            gs.client = None

    gs.crash_info = None

    if port is None:
        port = _find_free_port()

    love_exe = _find_love_exe()
    game_dir = os.getcwd()
    gs.stdout_buf.clear()
    gs.process = subprocess.Popen(
        [love_exe, game_dir, "--devport=" + str(port)],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    threading.Thread(target=_drain_pipe, args=(gs.process.stdout, gs.stdout_buf), daemon=True).start()

    for attempt in range(50):
        time.sleep(0.2)
        rc = gs.process.poll()
        if rc is not None:
            raise RuntimeError(f"Game exited during startup (exit code {rc}).")
        try:
            client = GameClient(port=port)
            client.send("ping")
            gs.client = client
            return client
        except (ConnectionRefusedError, OSError):
            continue
    raise RuntimeError("Could not connect to game after 10s. Is Love2D installed?")


def get_stdout(gs: GameState, limit=100) -> list[str]:
    return list(gs.stdout_buf)[-limit:]


def stop_game(gs: GameState):
    """Kill the game process and close the connection."""
    if gs.client:
        try:
            gs.client.close()
        except Exception:
            pass
        gs.client = None
    if gs.process:
        gs.process.terminate()
        gs.process = None
    gs.crash_info = None
