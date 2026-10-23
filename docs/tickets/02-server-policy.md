# 02: Server policy with the default chain

**What to build:** An installable server plugin that implements the default policy end to end: the Go peak preset, the primary model, the OpenRouter → Free → Muse chain, pre-turn switching, and the off-peak return. Configuration persists globally. A session managed by the plugin changes model at the boundary without the user touching `/models`.

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] The plugin loads from a local path and registers without errors.
- [ ] With force mode set to peak, a prompt on a new session uses the first available chain candidate.
- [ ] With force mode set to off-peak, the next prompt returns to the primary model.
- [ ] A candidate whose provider is missing from the catalog is skipped, and the reason is recorded.
- [ ] Configuration survives a server restart.
- [ ] Policy decisions are covered by table-driven tests at the pure-decision seam.
