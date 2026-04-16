"""
Agent tools for interacting with the running Love2D game.
Provides: game_start, game_interact
"""
import ex6
from _ex6.game_client import GameClient, start_game, get_stdout


GAME_TESTING_PROMPT = """\
<game_testing>
A game instance has started.
You now have tools to interact with the running Love2D game for testing.

WORKFLOW:
1. Call game_start() to launch the game and connect.
2. Use game_interact(cmd, ...) to send commands.
3. Use time.sleep(seconds) to let the game simulate between commands.

AVAILABLE COMMANDS (via game_interact):
  ping - Health check.
  get_scene - Get the current scene name.
  get_state - Get full game state: scene, entities, run info.
  spawn_entity(entityId, x, y) - Spawn an entity by type id at position.
  deploy_squad(squadId, x, y) - Deploy a squad at position.
  goto_scene(scene) - Switch to a scene by name.
  keypressed(key) - Simulate a key press.
  click(x, y, button) - Simulate a mouse click.
  eval(code) - Run arbitrary Lua code.
  read_stdout(limit) - Read last `limit` lines of game stdout (default 100). The agent cannot see game output otherwise.

TIPS:
- The game boots to "title_scene". Use game_interact("goto_scene", scene="battle_scene") to enter battle.
- In battle_scene, press 'q' to spawn test units: game_interact("keypressed", key="q")
- Use game_interact("get_state") to see all entities, positions, health, etc.
- Use game_interact("eval", code="...") to run any Lua code. Access globals: g, consts, etc.
- game_interact("eval", code="return g.hasRun()") checks if a run is active.
- game_interact("eval", code="g.newRun()") creates a new run.
- Entity types: militia, archer (allies), demon, imp (enemies).
- Entity fields: id, type, x, y, health, maxHealth, side, moveSpeed, attackDamage, attackSpeed, attackRange.
- After spawning entities, wait a few frames for physics/AI to kick in, then get_state to verify.

EXAMPLE SESSION:
  game_start()
  game_interact("ping")                           # => "pong"
  game_interact("eval", code="g.newRun()")         # create a run
  game_interact("goto_scene", scene="battle_scene") # enter battle
  time.sleep(0.5)                                     # let scene initialize
  game_interact("keypressed", key="q")             # spawn test units
  time.sleep(0.8)                                    # let them fight for 2 sec
  game_interact("get_state")                        # check who's alive
</game_testing>
"""


KEY = "game_tools:client"


def _get_client(ctx) -> GameClient:
    if KEY not in ctx.data_volatile:
        ctx.data_volatile[KEY] = GameClient()
    return ctx.data_volatile[KEY]


def game_start(ctx: ex6.Context) -> str:
    """Launch the Love2D game and connect to it. Must be called before game_interact. Returns 'connected' on success."""
    start_game(_get_client(ctx))
    return GAME_TESTING_PROMPT


def _parse_response(resp):
    """Extract the useful value from a raw JSON response dict."""
    resp.pop("id", None)
    resp.pop("cmd", None)
    if len(resp) == 1:
        return next(iter(resp.values()))
    return resp


def game_interact(ctx, cmd: str, **kwargs) -> dict:
    """Send a command to the running game and get a response. First arg is the command name (e.g. 'ping', 'get_state', 'eval'). Remaining kwargs are command-specific parameters. Returns the JSON response as a dict."""
    gc = _get_client(ctx)

    # Local-only commands
    if cmd == "read_stdout":
        limit = kwargs.get("limit", 100)
        stdout = "\n".join(get_stdout(gc, limit)) or "(no output)"
        if gc.crash_info:
            raise RuntimeError(f"{stdout}\n\nGAME CRASHED:\n{gc.crash_info}")
        return stdout

    if gc.crash_info:
        raise RuntimeError(gc.crash_info)

    if not gc._sock:
        raise RuntimeError("game not started. call game_start() first.")

    try:
        resp = gc.send(cmd, **kwargs)
    except Exception as e:
        gc.stop()
        raise RuntimeError(f"connection lost: {e}")

    if "crash" in resp:
        gc.crash_info = resp["crash"]
        gc.stop()
        raise RuntimeError(f"GAME CRASHED:\n{gc.crash_info}")

    result = _parse_response(resp)
    return str(result) if isinstance(result, bool) else result
