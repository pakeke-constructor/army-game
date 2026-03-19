# TASK: Implement Event Bus and Question Bus with Scope system

Replace the catx11 hardcoded g.call/g.ask pattern with a flexible Scope-based system. Scopes can be registered/unregistered dynamically, allowing blessings, perks, squads, spells, scenes, etc. to all participate in event/question dispatch without modifying g.call/g.ask.
---

<plan>

Summary:
Replace catx11's hardcoded g.call/g.ask with a Responder-based system. A Responder is a plain table of handlers (keyed by event/question name), registered via g.addResponder(). Internally, a global per-event and per-question cache is built incrementally on add — no finalize step needed. Dispatch is O(relevant responders) not O(all).

---

CORE CONCEPT:

A Responder is just a plain table of handlers, like a catx11 upgrade definition:
  { tokenDestroyed = function(...) end, getUnitDamage = function(...) return 5 end }

g.addResponder(handlers) validates keys, populates caches, returns a handle.
handle:remove() cleans up caches.

---

INTERNAL CACHES (module-level in g.lua):

  eventCache[eventName] -> list of {func, handle}
  questionCache[questionName] -> list of {func, handle}

g.addResponder scans the table, classifies each key as event or question, inserts into the relevant cache list. This mirrors catx11's finalizeBusCacheForUpgrade but happens immediately on add.

g.call(ev, arg1, ...) does:
  1. arg1[ev](arg1, ...) if present (catx11 pattern kept)
  2. iterate eventCache[ev], call each func

g.ask(q, arg1, ...) does:
  1. check arg1[q], reduce
  2. iterate questionCache[q], reduce each answer

---

FILES:

1. src/Responder.lua (~30-40 lines)
   - Small class or just a table with :remove() method
   - :remove() sets self.dead = true, removes entries from the global caches
   - Optional: :isAlive()

2. src/g.lua additions (~60-70 lines)
   - g.defineEvent(name), g.isEvent(name)
   - g.defineQuestion(name, reducer, defaultValue), g.getQuestionInfo(name)
   - g.addResponder(handlers) -> handle
     - Validates each key is a known event or question
     - Inserts into eventCache / questionCache
     - Returns Responder handle
   - g.call(ev, arg1, ...)
   - g.ask(q, arg1, ...)

---

INVALIDATION:

Primary mechanism: handle:remove(). Covers blessings removed, battle ending, etc.

Optional: g.addResponder(handlers, condition) where condition is a function.
If provided, g.call/g.ask check condition() before invoking. Lazily compact dead entries.
This handles "temporarily inactive" cases (e.g. perk disabled while stunned).
Can defer this to a follow-up if not needed immediately.

---

USAGE PATTERNS:

Blessing gained:
  local h = g.addResponder({ battleWon = function(...) run.mana = run.mana + 2 end })
  -- store h, call h:remove() when blessing is lost

Per-unit perk:
  local h = g.addResponder({ getUnitDamage = function(unit) return 5 end })
  -- h:remove() when unit dies

Scene:
  function scene:enter()
      self._responder = g.addResponder({ unitDied = function(...) self:onUnitDied(...) end })
  end
  function scene:leave()
      self._responder:remove()
  end

---

EDGE CASES / NOTES:
- Events/questions must be defined before addResponder is called (same constraint as catx11).
- Responder handles are lightweight; creating/destroying many is fine.
- Cache removal in handle:remove() should be O(cache-list-length) for that event. Fine for typical sizes. If hot, swap-remove.
- arg1 dispatch is separate from responders (same as catx11). arg1 is typically the "target" entity.

</plan>

<done_criteria>

1. src/Responder.lua exists: glob("src/Responder.lua") returns a match.
2. Responder has a :remove() method: search("function.*:remove", match="src/Responder.lua", max_results=1) matches.
3. g.defineEvent exists: search("function g.defineEvent", match="src/g.lua", max_results=1) matches.
4. g.isEvent exists: search("function g.isEvent", match="src/g.lua", max_results=1) matches.
5. g.defineQuestion exists: search("function g.defineQuestion", match="src/g.lua", max_results=1) matches.
6. g.getQuestionInfo exists: search("function g.getQuestionInfo", match="src/g.lua", max_results=1) matches.
7. g.addResponder exists: search("function g.addResponder", match="src/g.lua", max_results=1) matches.
8. g.call exists and uses eventCache: read_body("src/g.lua", "g.call") contains "eventCache".
9. g.ask exists and uses questionCache and reducer: read_body("src/g.lua", "g.ask") contains "questionCache" and "reducer".
10. g.call dispatches to arg1: read_body("src/g.lua", "g.call") contains "arg1[ev]".
11. g.ask dispatches to arg1: read_body("src/g.lua", "g.ask") contains "arg1[q]".
12. g.addResponder validates keys: read_body("src/g.lua", "g.addResponder") references isEvent and getQuestionInfo.
13. reducers required in g.lua: search("require.*reducers", match="src/g.lua", max_results=1) matches.

</done_criteria>

<log>
[2026-03-19T17:34:40Z] [CREATED] Implement Event Bus and Question Bus with Scope system
[2026-03-19T17:34:47Z] [LEARNING] reducers.lua already ported to Army game
[2026-03-19T17:36:54Z] [LEARNING] Multi-listener pattern (like Tree with many upgrades) would need either: many scopes or a CompoundScope
[2026-03-19T18:43:30Z] [PROGRESS] Implemented event/question bus: Responder.lua + g.lua additions. All 13 done criteria pass.
[2026-03-19T19:44:46Z] [PROGRESS] Replaced Responder system with ephemeral addHandler + ent.handlers list
</log>


<meta>
status: open
created_at: 2026-03-19T17:34:40Z
</meta>
-03-19T17:34:40Z
</meta>
meta>
