# Own only the models in the managed set

**Status:** accepted

A user's model can come from five places: a manual choice in the session, a command that switches the model before prompting, an agent's configured model, a project `opencode.json`, or the global config. Session models win over config; project config wins over global; commands call `switchModel` themselves. If the plugin treated every session as fair game it would silently override deliberate choices. We therefore manage a session only when its effective model is the primary or an enabled chain candidate. The first time we manage one, we record its **origin model** and restore it when peak ends. Any model change we did not make pins the session, whatever its source. Agent-configured sessions and child sessions are left alone by default. The only ways in are explicit: a project sets `adopt: true`, or the user chooses "Adopt this session".

## Consequences

- Installing the plugin does not change a project whose default model is outside the managed set. The page must say so and offer "Adopt this session"; a project can opt in wholesale with `adopt: true`.
- Off-peak restoration returns the model the session had, not necessarily the primary. A project that defaults to the free model stays on the free model.
- A command that picks a model pins the session for the rest of its life unless the user resumes automatic control; that is deliberate, because the command expressed an intent the plugin cannot see.
- Prose rules in `AGENTS.md` are not parsed. The plugin respects the resolved model, not instructions about models.
