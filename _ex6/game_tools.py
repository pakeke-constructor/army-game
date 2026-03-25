"""
Agent tools for interacting with the running Love2D game.
Provides: game_start, game_interact, game_wait, test_game
"""
import time
from _ex6.game_client import GameClient, start_game, stop_game, _get_command_docs

_client = None


GAME_TESTING_PROMPT = f"""\
<game_testing>
You have tools to interact with the running Love2D game for testing.

WORKFLOW:
1. Call game_start() to launch the game and connect.
2. Use game_interact(cmd, ...) to send commands.
3. Use game_wait(frames) to let the game simulate between commands.

AVAILABLE COMMANDS (via game_interact):
{_get_command_docs()}

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
  game_interact("ping")                           # => {{"pong": true}}
  game_interact("eval", code="g.newRun()")         # create a run
  game_interact("goto_scene", scene="battle_scene") # enter battle
  game_wait(30)                                     # let scene initialize
  game_interact("keypressed", key="q")             # spawn test units
  game_wait(120)                                    # let them fight for 2 sec
  game_interact("get_state")                        # check who's alive
</game_testing>
"""


def game_start(ctx) -> str:
    """Launch the Love2D game and connect to it. Must be called before game_interact. Returns 'connected' on success."""
    global _client
    _client = start_game()
    return GAME_TESTING_PROMPT


def game_interact(ctx, cmd: str, **kwargs) -> dict:
    """Send a command to the running game and get a response. First arg is the command name (e.g. 'ping', 'get_state', 'eval'). Remaining kwargs are command-specific parameters. Returns the JSON response as a dict."""
    global _client
    if not _client:
        raise RuntimeError("game not started. call game_start() first.")
    try:
        return _client._send(cmd, **kwargs)
    except Exception as e:
        _client = None
        raise RuntimeError(f"connection lost: {e}")


def game_wait(ctx, frames: int = 60) -> str:
    """Wait for approximately N frames (at 60fps). Default 60 frames = ~1 second. Useful to let the game simulate before checking state."""
    time.sleep(frames / 60.0)
    return f"waited {frames} frames (~{frames/60.0:.2f}s)"


