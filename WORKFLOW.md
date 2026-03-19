


## WORKFLOW:

- ((HUMAN: Define feature))
- Dispatch agent to plan feature. (opus46)
- Dispatch agent to create test-code for feature. (codex53)
- IMPLEMENT: Dispatch agent to plan pseudocode structure for feature (opus)
- IMPLEMENT: Dispatch agent to write code (codex53)
- TEST: codex53 tests against test code


## TO THINK ABOUT:
How do we make the plan -> execute step more seamless?
Maybe the planner gets allocated an agent: `start_agent`?

