"""
TCP client for communicating with the Love2D agent bridge.
The game exposes a JSON-over-TCP socket on port 27015 (DEV_MODE only).
"""
import socket
import json
import time
import subprocess
import os

_DEFAULT_PORT = 27015

class GameClient:
    """Connects to the running Love2D game's agent bridge."""

    def __init__(self, host="127.0.0.1", port=_DEFAULT_PORT, timeout=5.0):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(timeout)
        self.sock.connect((host, port))
        self._buf = b""
        self._id = 0

    def _send(self, cmd, **kwargs):
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
        return json.loads(line)

    def ping(self):
        """Health check. Returns {pong: true}."""
        return self._send("ping")

    def get_scene(self):
        """Get the current scene name. Returns {scene: str}."""
        return self._send("get_scene")

    def get_state(self):
        """Get full game state: current scene, all entities (id, type, x, y, health, maxHealth, side), and run info (health, maxHealth, mana, money, food, day). Returns a dict."""
        return self._send("get_state")

    def spawn_entity(self, entity_id, x, y):
        """Spawn an entity by type id at position (x,y). Only works during battle. Known types: militia, archer, demon, imp. Returns {spawned: int, type: str}."""
        return self._send("spawn_entity", entityId=entity_id, x=x, y=y)

    def deploy_squad(self, squad_id, x, y):
        """Deploy a squad at position (x,y). Only works during battle with a run active. Returns {deployed: [int]}."""
        return self._send("deploy_squad", squadId=squad_id, x=x, y=y)

    def goto_scene(self, scene):
        """Switch to a scene by name. Known scenes: title_scene, battle_scene, map_scene. Returns {ok: true}."""
        return self._send("goto_scene", scene=scene)

    def keypressed(self, key):
        """Simulate a key press. Uses Love2D key names (e.g. 'q', 'space', 'return'). Returns {ok: true}."""
        return self._send("keypressed", key=key)

    def click(self, x, y, button=1):
        """Simulate a mouse click at screen position (x,y). button=1 for left, 2 for right. Returns {ok: true}."""
        return self._send("click", x=x, y=y, button=button)

    def eval(self, code):
        """Run arbitrary Lua code in the game's main thread. Can access all globals (g, consts, etc). If the code returns a value, it's in {result: ...}. Otherwise {ok: true}. Errors return {error: str}."""
        return self._send("eval", code=code)

    def close(self):
        """Close the connection."""
        self.sock.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


# -------------------------------------------------------
# Collect command docs for agent injection
# -------------------------------------------------------
def _get_command_docs():
    """Build a help string from GameClient method docstrings."""
    import inspect
    lines = []
    for name, method in inspect.getmembers(GameClient, predicate=inspect.isfunction):
        if name.startswith("_"):
            continue
        doc = (method.__doc__ or "").strip()
        sig = inspect.signature(method)
        params = [p for p in sig.parameters if p != "self"]
        param_str = ", ".join(params)
        lines.append(f"  {name}({param_str}) - {doc}")
    return "\n".join(sorted(lines))


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

def start_game(port=_DEFAULT_PORT):
    """Launch the Love2D game and connect. Returns a GameClient."""
    global _game_process, _game_client
    if _game_client:
        try:
            _game_client.ping()
            return _game_client
        except Exception:
            _game_client = None

    love_exe = _find_love_exe()
    game_dir = os.getcwd()
    _game_process = subprocess.Popen(
        [love_exe, game_dir],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    # wait for the socket to be ready
    for attempt in range(50):
        time.sleep(0.2)
        try:
            _game_client = GameClient(port=port)
            _game_client.ping()
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
