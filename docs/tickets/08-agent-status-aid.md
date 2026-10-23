# 08: Agent-facing status aid

**What to build:** A read-only `peak_status` tool and a short `peak-switcher` skill, both optional. The tool answers "why is my model X?" for the calling session with the same facts the page shows. The skill tells the agent not to switch models on its own and to point policy changes at `/peak`.

**Blocked by:** 02.

**Status:** ready-for-agent

- [ ] `peak_status` reports mode, force setting, next boundary, effective model, origin model, ownership state with reason, candidate availability or cooldown, and the last switch with its cause.
- [ ] It works for managed, pinned, and unmanaged sessions without changing any state.
- [ ] The report comes from a pure formatter with tests for each ownership state and for the all-candidates-failed case.
- [ ] The skill is registered only when `agent.skill` is on, carries `autoinvoke: true`, and its guidance is visible to the model.
- [ ] With `agent.statusTool` and `agent.skill` both off, neither surface exists.
- [ ] Per-project options can disable either one without touching the global configuration.
