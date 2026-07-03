


from _ex6.models import M
from _ex6.tools import read_headers, read_body, glob, search, write_file, edit_file, read_file, edit_file_lines, escalate, bash, explore_agent, CLAUDE_MD, ENV_PROMPT, git_working_tree, add_tool_repetition_guard
from _ex6.skills import load_skill
from _ex6.lua_coding_style import SYSTEM_PROMPT_CODING_STYLE
from _ex6.tasks import plan_add_log, plan_done, plan_list, plan_read, plan_write
from _ex6.web.web_tools import web_search, websearch_agent
from _ex6.love2d_docs.love2d_docs import love2d_docs
from _ex6.game_tools import game_start, game_interact
from _ex6.provider import cache_manually
import ex6
from ex6 import Context, Message




MAIN_SYSTEM_PROMPT = ex6.Message(
role ="system",
overview="main-system",
content="""\
You are a coding agent working alongside an experienced engineer in a terminal UI.

<goal>
Solve user request with minimal bloat.
Prefer direct implementation path.
</goal>

<agent_strategy>
- Understand request, constraints, user intent first.
- Map out problem + solution, and discover more about the codebase. Prioritize read_headers.
- Complete changes: write code, edit files.

Always check changes afterwards. (Check git diff, run tests, or read file(s).)
</agent_strategy>

<agent_tactics>
- Try the simplest approach first. Don't overthink.
- Tool call(s) to verify, then act. Don't read the whole codebase before a 2-line edit.
- If a search returns what you need, stop searching. Don't keep exploring "just in case."
- If your approach is blocked, don't brute force. Step back, try a different angle, or ask.
- Avoid backwards-compatibility hacks. If something is unused, delete it.
</agent_tactics>

<output_rules>
Plain text only. No markdown headers, no tables, no emojis. Short lines.
DO NOT explain your reasoning or thinking process. DO NOT narrate what you are about to do or what you just did.
When you have tool calls to make, make them IMMEDIATELY — no preamble, no "Let me look at...", no "I'll now...".
After tool calls, say nothing unless there's a result to report or a question to ask.
The ONLY acceptable text output is: a direct answer, a clarifying question, or a blocker.
</output_rules>

<code_editing_rules>
- Don't add features, refactor, docstrings, comments, or type annotations beyond what was asked.
- Don't add error handling for scenarios that can't happen.
- Three similar lines > premature abstraction.
</code_editing_rules>

<working_style>
- Read code before modifying it. Never propose changes to code you haven't seen.
- Before using an API or module, look up the actual definition first.
- Write the simplest code that works. Avoid over-engineering, unnecessary abstractions, and speculative features.
- Prefer editing existing files over creating new ones.
</working_style>
"""
)




# SMART_MODEL = "openai/gpt-5.2-codex"
# SMART_MODEL = "openai/gpt-5.1-codex-mini"
# SMART_MODEL = M.SONNET_46.id



MAIN_TOOLS = [
    read_file, glob, search, read_headers, read_body,
    write_file, edit_file, edit_file_lines,
    # web_search, websearch_agent,
    plan_done, plan_read, plan_write,
    git_working_tree,
    love2d_docs,
    load_skill
]

MAIN_SYSTEM_PROMPT = MAIN_SYSTEM_PROMPT.with_tools(MAIN_TOOLS)

CODING_STYLE_PROMPT = ex6.Message(role="system", overview="coding-style", content=SYSTEM_PROMPT_CODING_STYLE)



CLAUDE_MD = ex6.Message(role="system", content=open("CLAUDE.md","r").read(), overview="CLAUDE.md")


c_opus = Context("c_opus", yolo=False, model=M.OPUS_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    CLAUDE_MD,
])
cache_manually(c_opus)


c_sonnet = Context("c_sonnet", yolo=False, model=M.OPUS_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    CLAUDE_MD,
])
cache_manually(c_sonnet)




Context("c_codex", yolo=False, model=M.CODEX_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    CLAUDE_MD,
])


c_gem = Context("c_gem", yolo=False, model=M.GEMINI_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    CLAUDE_MD,
])
add_tool_repetition_guard(c_gem)


Context("c_glm", yolo=False, model=M.GLM_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    CLAUDE_MD,
])




OMNI_PROMPT = ex6.Message(role = "system", 
tools = [read_file, read_headers, search, glob,],
content="""
You have a specialized skill, on top of your existing coding abilities:
*You can see other codebases*.

As such, your main tasks will involve bringing code over from other codebases,
or learning about other codebases in order to write better code in this codebase.
""")

# TODO: it makes a LOT of sense to extract OMNI-AGENT into core ex6.
# Then we can reuse it for other stuff
# IDEA:
# . 
# new_omni_agent({
#     core_project = "army_game",
#     projects = {
#         "army_game": ("C:\\path...", "Army-game is a .... blah blah"),
#         "ex6": ("C:\\path...", "ex6 is ... blah blah"),
#         ...
#     }
# })
# With this, we can reuse the idea of omni-agent across multiple projects.


# coder = Context("c_omni", yolo=False, model=M.GPT53_CODEX.id, reasoning="medium", messages=[
#     MAIN_SYSTEM_PROMPT,
#     OMNI_PROMPT,
#     ENV_PROMPT,
# ])




ex6.state.current = coder


