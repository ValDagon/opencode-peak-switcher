# 06: Error cascade and cooldowns

**What to build:** In-turn fallback for availability failures. A `402` or `403` from OpenRouter moves the same turn to Free without the user resending the prompt; an exhausted free route moves it to Muse. Failed candidates enter cooldown with a visible reason and expiry. If the whole chain is unusable, the turn continues on the primary model and the page explains why. Transient transport failures are left to OpenCode's normal retry.

**Blocked by:** 01, 02.

**Status:** ready-for-agent

- [ ] A stub `402` on the first candidate makes the retry use the next candidate in the same turn.
- [ ] A second failure cascades again, up to Muse.
- [ ] The failed candidate is skipped for its cooldown and the page shows why and until when.
- [ ] When everything fails, the primary is used and the reason is visible.
- [ ] A transport failure does not trigger a switch.
- [ ] `429` requires two consecutive failures on the same model before switching.
- [ ] Error classification is covered by a table-driven test.
