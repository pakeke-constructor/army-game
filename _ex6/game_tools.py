"""
Agent tools for interacting with the running Love2D game.
Provides: game_start, game_interact
"""
import ex6
from _ex6.game_client import GameClient, GameState, start_game, stop_game, check_crash, get_stdout, get_stderr


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
- Use game_interact("read_stdout", limit=100) to see recent game console output.

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


KEY = "game_tools:state"


def _get_state(ctx) -> GameState:
    """Get or create the GameState from ctx.data."""
    if KEY not in ctx.data:
        ctx.data[KEY] = GameState()
    return ctx.data[KEY]


def _check_crash_gate(ctx):
    """If the game has crashed, raise with crash info immediately."""
    crash = check_crash(_get_state(ctx))
    if crash:
        raise RuntimeError(crash)


def game_start(ctx: ex6.Context) -> str:
    """Launch the Love2D game and connect to it. Must be called before game_interact. Returns 'connected' on success."""
    state = _get_state(ctx)
    start_game(state)
    return GAME_TESTING_PROMPT


def game_interact(ctx, cmd: str, **kwargs) -> dict:
    """Send a command to the running game and get a response. First arg is the command name (e.g. 'ping', 'get_state', 'eval'). Remaining kwargs are command-specific parameters. Returns the JSON response as a dict."""
    state = _get_state(ctx)
    _check_crash_gate(ctx)

    # Local-only commands (don't need a live connection)
    if cmd == "read_stdout":
        limit = kwargs.get("limit", 100)
        lines = get_stdout(state, limit)
        return "\n".join(lines) if lines else "(no output)"

    client = state.client
    if not client:
        raise RuntimeError("game not started. call game_start() first.")
    try:
        result = client.send(cmd, **kwargs)
        return str(result) if isinstance(result, bool) else result
    except Exception as e:
        crash = check_crash(state)
        if crash:
            raise RuntimeError(crash)
        state.client = None
        stderr = "\n".join(get_stderr(state, 50))
        stdout = "\n".join(get_stdout(state, 50))
        raise RuntimeError(f"connection lost: {e}\n\nStderr:\n{stderr or '(empty)'}\n\nStdout (last 50):\n{stdout or '(empty)'}")
