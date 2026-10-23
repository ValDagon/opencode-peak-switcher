# 01: Prove hook-based switching in a live session

**What to build:** A throwaway plugin that proves the two runtime mechanics the whole design rests on, before any product code exists. First: a `prompt` hook that switches the session model on admission is honoured by the request being admitted. Second: a `retry` hook that calls `switchModel` and forces an immediate retry makes the retry use the new model, inside one turn. All of it runs in the disposable lab profile from `scripts/lab.sh`, never in the daily OpenCode profile.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The spike runs through `scripts/lab.sh` with its own XDG directories and a private `--standalone` server.
- [ ] A session created in the lab is absent from the real `~/.local/share/opencode/opencode.db`.
- [ ] A local plugin registers a `prompt` hook and a `retry` hook without deadlocking the session.
- [ ] With `PEAK_FORCE=peak`, a new prompt reaches the provider on the chain's first model.
- [ ] With `PEAK_FAIL_MODEL=one PEAK_FAIL_STATUS=402`, the retry uses the next model, and the user does not resend the prompt.
- [ ] The fake provider's JSON log shows the model of every attempt, proving the switch.
- [ ] Findings, including anything that contradicted the source reading, are written to `docs/spikes/in-turn-fallback.md`.
- [ ] The TUI entrypoint can round-trip one RPC method and receive one event from the private server.
