# 01: Prove hook-based switching in a live session

**What to build:** A throwaway plugin that proves the two runtime mechanics the whole design rests on, before any product code exists. First: a `prompt` hook that switches the session model on admission is honoured by the request being admitted. Second: a `retry` hook that calls `switchModel` and forces an immediate retry makes the retry use the new model, inside one turn.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] A local plugin registers a `prompt` hook and a `retry` hook without deadlocking the session.
- [ ] With a forced peak flag, a new prompt reaches the provider on the chain's first model.
- [ ] A stub provider returns `402` once; the retry uses the next model, and the user does not resend the prompt.
- [ ] The request log shows the model of every attempt, proving the switch.
- [ ] Findings, including anything that contradicted the source reading, are written to `docs/spikes/in-turn-fallback.md`.
- [ ] The TUI entrypoint can round-trip one RPC method and receive one event from a live server.
