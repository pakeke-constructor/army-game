"""
TCP client for communicating with the Love2D agent bridge.
The game exposes a JSON-over-TCP socket when launched with --devport=PORT.
"""
import socket
import json
import time
import subprocess
import os

_DEFAULT_PORT = 27015

def _find_free_port():
    """Bind to port 0 and let the OS pick a free port."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port

class GameClient:
    """Connects to the running Love2D game's agent bridge."""

    def __init__(self, host="127.0.0.1", port=_DEFAULT_PORT, timeout=5.0):
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
        resp.pop("id", None)
        resp.pop("cmd", None)
        if len(resp) == 1:
            return next(iter(resp.values()))
        return resp
    def close(self):
        """Close the connection."""
        self.sock.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


# -------------------------------------------------------
# Boot the game
# -------------------------------------------------------
_game_process = None
_game_client = None

def _find_love_exe():
    """Try common locations for love.exe on Windows."""
    candidates = [
        r"C:\Program Files\LOVE\love.exe",
        r"C:\Program Files (x86)\LOVE\love.exe",
    ]
    # also check PATH
    for c in candidates:
        if os.path.isfile(c):
            return c
    return "love"  # hope it's on PATH

def start_game(port=None):
    """Launch the Love2D game and connect. Returns a GameClient."""
    global _game_process, _game_client
    if _game_client:
        try:
            _game_client.send("ping")
            return _game_client
        except Exception:
            _game_client = None

    if port is None:
        port = _find_free_port()

    love_exe = _find_love_exe()
    game_dir = os.getcwd()
    _game_process = subprocess.Popen(
        [love_exe, game_dir, "--devport=" + str(port)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    # wait for the socket to be ready
    for attempt in range(50):
        time.sleep(0.2)
        try:
            _game_client = GameClient(port=port)
            _game_client.send("ping")
            return _game_client
        except (ConnectionRefusedError, OSError):
            continue
    raise RuntimeError("Could not connect to game after 10s. Is Love2D installed?")

def stop_game():
    """Kill the game process and close the connection."""
    global _game_process, _game_client
    if _game_client:
        try:
            _game_client.close()
        except Exception:
            pass
        _game_client = None
    if _game_process:
        _game_process.terminate()
        _game_process = None
