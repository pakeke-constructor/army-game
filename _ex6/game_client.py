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


@dataclass
class GameClient:
    process: subprocess.Popen | None = None
    crash_info: str | None = None
    stdout_buf: collections.deque = field(default_factory=lambda: collections.deque(maxlen=2000))
    _sock: socket.socket | None = field(default=None, repr=False)
    _buf: bytes = field(default=b"", repr=False)
    _id: int = field(default=0, repr=False)

    def send(self, cmd, **kwargs):
        """Send a command, return parsed JSON response dict."""
        self._id += 1
        msg = {"cmd": cmd, "id": self._id, **kwargs}
        self._sock.sendall((json.dumps(msg) + "\n").encode())
        # read one newline-delimited JSON response
        while b"\n" not in self._buf:
            chunk = self._sock.recv(4096)
            if not chunk:
                raise ConnectionError("connection closed")
            self._buf += chunk
        line, self._buf = self._buf.split(b"\n", 1)
        return json.loads(line)

    def connect(self, host, port, timeout=5.0):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.settimeout(timeout)
        self._sock.connect((host, port))
        self._buf = b""
        self._id = 0

    def stop(self):
        if self._sock:
            try: self._sock.close()
            except Exception: pass
            self._sock = None
        if self.process:
            self.process.terminate()
            self.process = None


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
# API
# -------------------------------------------------------

def start_game(gc: GameClient, port=None):
    """Launch the Love2D game and connect."""
    if gc._sock:
        try:
            gc.send("ping")
            return
        except Exception:
            gc.stop()

    gc.crash_info = None
    gc.stdout_buf.clear()

    if port is None:
        port = _find_free_port()

    love_exe = _find_love_exe()
    game_dir = os.getcwd()
    gc.process = subprocess.Popen(
        [love_exe, game_dir, "--devport=" + str(port)],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    threading.Thread(target=_drain_pipe, args=(gc.process.stdout, gc.stdout_buf), daemon=True).start()

    for attempt in range(50):
        time.sleep(0.2)
        rc = gc.process.poll()
        if rc is not None:
            raise RuntimeError(f"Game exited during startup (exit code {rc}).")
        try:
            gc.connect("127.0.0.1", port)
            gc.send("ping")
            return
        except (ConnectionRefusedError, OSError):
            continue
    raise RuntimeError("Could not connect to game after 10s. Is Love2D installed?")


def get_stdout(gc: GameClient, limit=100) -> list[str]:
    return list(gc.stdout_buf)[-limit:]
