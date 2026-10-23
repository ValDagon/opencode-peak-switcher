# Peak Switcher — Spec

## Problem Statement

DeepSeek V4.1 Flash costs twice as much during its peak windows. On OpenCode Go those windows are **01:00–04:00 and 06:00–10:00 UTC, Monday through Friday**; every other hour, including weekends, is off-peak. A user who wants to keep working without paying peak rates has to watch the clock and run `/models` by hand, every time, and remember to switch back. The same user may not have budget on OpenRouter, may exhaust the free DeepSeek route, or may be in a region where the cheap Contributor model is unavailable — and today each of those failures stops the turn instead of falling through to the next option.

## Solution

An OpenCode plugin, installed with one command, that treats the model as a policy decision rather than a manual one. It moves managed sessions along a user-editable fallback chain when peak starts, returns them to the primary model when peak ends, and falls through the chain inside the same turn when a provider turns out to be unavailable. A `/peak` page in the terminal shows the current mode, a countdown to the next boundary, the effective model, and the availability of every candidate; the chain is edited there by name, not by hand-written model IDs. Choosing a model manually pins the session, so the plugin never fights the user.

Default policy:

| Moment | Model |
| --- | --- |
| Off-peak | `opencode-go/deepseek-v4.1-flash` (primary) |
| Peak, step 1 | `openrouter/~deepseek/deepseek-flash-latest` |
| Peak, step 2 | `opencode/deepseek-v4.1-flash-free` |
| Peak, step 3 | `opencode-go/muse-spark-1.3-contributor` |
| Everything unavailable | primary, even at peak, with a visible reason |

## User Stories

1. As a user, I want a session to move off the primary model when a peak window starts, so that I do not pay peak rates without noticing.
2. As a user, I want a session to return to the primary model when peak ends, so that I get the model I actually chose for normal work.
3. As a user, I want to see how long until the next boundary, so that I can decide whether to wait or keep working.
4. As a user, I want to force peak or off-peak for a test, so that I can verify the policy without waiting for 01:00 UTC.
5. As a user, I want to define custom peak windows, so that the plugin works for providers other than OpenCode Go.
6. As a user, I want an ordered fallback chain, so that the first available candidate wins and the order is mine.
7. As a user, I want a candidate whose provider is not connected to be skipped automatically, so that the chain never gets stuck on an account I do not have.
8. As a user, I want a disabled or absent model to be skipped automatically, so that a catalog change does not break my turns.
9. As a user, I want an OpenRouter budget failure to fall through to the free route, so that a zero balance does not stop my work.
10. As a user, I want an exhausted free route to fall through to Muse, so that limited-time free capacity is not a dead end.
11. As a user, I want Muse to be the last step, so that a different model and its data-training terms are only used when nothing else works.
12. As a user, I want the whole chain to fit inside the same turn, so that I do not have to resend my prompt after a fallback.
13. As a user, I want the fallback to happen before any output is produced, so that the transcript never mixes two models mid-answer.
14. As a user, I want a failure after output has started to be shown honestly, so that I can decide what to do next.
15. As a user, I want the plugin to return to the primary model after the chain was used for an error and the primary recovered, so that a transient failure does not downgrade me for the rest of the day.
16. As a user, I want to reorder the chain, so that my cost and quality preferences are reflected without editing JSON.
17. As a user, I want to add and remove candidates, so that I can use a different model when my subscriptions change.
18. As a user, I want to pick models from the catalog by display name, so that I never have to type a provider/model ID.
19. As a user, I want the picker to show only models that support tools and text, so that I cannot configure a candidate that breaks the agent loop.
20. As a user, I want a warning when a candidate's context window is smaller than what the session already uses, so that a switch does not cause an immediate overflow.
21. As a user, I want my configuration to persist across restarts, so that I configure it once.
22. As a user, I want one global configuration, so that I do not repeat the setup in every project.
23. As a user, I want my manual model choice to pin the session, so that the plugin stops overriding me.
24. As a user, I want to see which sessions are pinned, so that I understand why the policy is not applying there.
25. As a user, I want a "Resume auto" action, so that I can hand a pinned session back to the policy.
26. As a user, I want subagents to be left alone by default, so that an agent configured with a specific model keeps it.
27. As a user, I want a compact status indicator, so that I know the mode and effective model without opening a page.
28. As a user, I want to see why the last switch happened, so that a surprise model change is explainable.
29. As a user, I want to see when a candidate is cooling down and why, so that I can tell a rate limit from a missing account.
30. As a user, I want to install with `opencode plugin add`, so that setup is one command.
31. As a user, I want the plugin to work over SSH, so that the interface does not depend on a browser or a desktop.
32. As a user, I want updates through `opencode plugin update`, so that I do not reinstall by hand.
33. As a user, I want the plugin to store no provider API keys, so that installing it does not create a second secret store.
34. As a user, I want the interface to work with the keyboard only, so that I can configure it from any terminal.

## Implementation Decisions

### Package shape

One package, `opencode-peak-switcher`, with three entrypoints:

- `.` — server plugin: configuration, policy, hooks, RPC registration.
- `./rpc` — the shared RPC definition, importable by the TUI entrypoint without pulling server code.
- `./tui` — the terminal interface: status slots, `/peak` page, editors.

Installed straight from GitHub: `opencode plugin add github:ValDagon/opencode-peak-switcher`. There is no npm publication, so the repository is the registry. A tag or commit can be pinned with `#v0.1.0`; an unpinned install follows the default branch and can be refreshed with `opencode plugin update`. The CLI auto-loads the TUI entrypoint from the package, so `cli.json` is not needed. The package manifest stays `private` so an accidental publish cannot happen.

### Configuration

Configuration lives in the server plugin's durable storage (`ctx.storage`, a global key/value namespace, not location-scoped). The TUI reads and writes it through RPC. Shape:

```ts
type ModelRef = { providerID: string; id: string; variant?: string }

type Candidate = {
  id: string          // stable local identifier, not the model ID
  model: ModelRef
  enabled: boolean
  label?: string      // optional user-facing note
}

type Config = {
  version: 1
  primary: ModelRef
  chain: Candidate[]
  peak:
    | { preset: "deepseek-go" }
    | { preset: "custom"; windows: { days: number[]; start: string; end: string }[] } // UTC, days 1=Mon..7=Sun
  force: "auto" | "peak" | "off-peak"
  switchBack: boolean        // default true
  cascadeOutsidePeak: boolean // default true
  manageSubagents: boolean   // default false
  cooldowns: {
    rateLimitMinutes: number   // default 15
    budgetMinutes: number      // default 60
    unavailableMinutes: number // default 10
  }
}
```

All windows are UTC. `start` and `end` are `HH:MM` and must not cross midnight; the editor rejects or splits an overnight range. The default `deepseek-go` preset is the two documented Go windows.

### Desired model

The policy is a pure function of a clock reading, the session record, the catalog, and the cooldown table:

```text
desired(session, now):
  if session is pinned: return session.model
  if peak(now) or not usable(primary, now):
    for candidate in enabled(chain):
      if usable(candidate.model, now) and fits(candidate.model, session):
        return candidate.model
    return primary                     # last resort, even at peak
  return primary
```

`usable(model, now)` means: the provider is present in the location's catalog, the model is enabled, and it is not in cooldown. `fits` compares the candidate's context limit against the session's recorded token usage, with a safety margin; it is a warning in the editor and a skip at runtime.

Peak is computed from UTC, not local time. The interface displays local time.

### Switching points

- **Before a turn:** the `prompt` hook computes the desired model and calls `session.switchModel` when it differs from the session's current model. Model resolution happens after admission, so this affects the request being admitted.
- **Inside a turn:** the `retry` hook handles availability failures. It marks the failed candidate, computes the next usable candidate, calls `session.switchModel`, and sets `decision = { retry: true, delay: 0 }`. The runner re-reads the session model before the next attempt, so the retry uses the new model.
- **Never mid-stream:** a failure after output has started is surfaced, not retried on another model. The retry hook has no `kind` field, so the classification below is what keeps title and compaction requests from causing surprising switches.

### Failure classification

| Signal | Class | Action | Cooldown |
| --- | --- | --- | --- |
| `402` | Budget or credits exhausted | Switch in-turn to the next candidate | 60 min |
| `403` | Budget window exhausted | Switch in-turn to the next candidate | Until `resets_at` if parseable, else 60 min |
| `429` | Rate limited | Switch after two consecutive failures on the same model in the turn | 15 min |
| Model not found / unavailable | Catalog unavailable | Switch in-turn | 10 min, or until the catalog changes |
| `in_flight_budget_exhausted` inside a `402` message | Transient | Retry the same model once, then cascade without a cooldown | none |
| Transport, timeout, `5xx` | Transient | Leave OpenCode's normal retry policy alone | none |
| Context overflow | Compaction | Leave OpenCode's overflow recovery alone | none |

The `retry` hook exposes `{ type, message, status?, attempt }` per failure; the OpenRouter `limit_source` is read from the message when present. The built-in retry budget is ten attempts, enough for the four-model chain.

### Pin detection

The plugin records the model it last applied per session. At the start of a `prompt` hook it compares the session's current model with that record:

- same → managed, continue.
- different → the user changed it, so the session becomes pinned.
- no record, first sight → pinned if the model is neither the primary nor a chain member, otherwise managed.

A session whose agent has an explicit model is treated as pinned, so agents such as reviewers keep their configured model. Child sessions are skipped unless `manageSubagents` is on. "Resume auto" clears the pin and the record; the next prompt applies the policy.

### Status and control surface

Two slots:

- `prompt.footer.status` and `home.footer.status` — a compact indicator: `PEAK 01:23:45 · DeepSeek Flash Latest`, or `OFF-PEAK · DeepSeek V4.1 Flash`.
- The `/peak` page and a palette command — the full view.

The page shows:

- force mode (Auto / Peak / Off-peak), local time, next boundary;
- primary model;
- each candidate with position, display name, provider, availability reason, context limit, and cooldown;
- pinned sessions with "Resume auto";
- the last switch: when, from, to, why.

Editing uses the native dialogs: a searchable model picker grouped by provider and filtered to tool-capable text models, actions to move a candidate up or down, toggle, remove, and add. Peak windows are edited through a preset selector plus a validated text form. Every edit writes the whole config through one RPC call and re-renders from the returned state.

### RPC

```ts
getState() -> State
updateConfig({ config }) -> State
resumeSession({ sessionID }) -> State
clearCooldown({ candidateID }) -> State
// event
stateChanged -> State
```

`State` carries config, the clock reading, peak/next boundary, cooldowns, pinned sessions, and the last action. It deliberately does **not** carry catalog availability: the TUI computes that from its own location catalog, because RPC registrations resolve to the most recently registered plugin instance and are not a safe way to ask "what is available in this project". The server computes availability independently inside each hook.

### Model references

- Primary: `opencode-go/deepseek-v4.1-flash`.
- OpenRouter: `openrouter/~deepseek/deepseek-flash-latest` (display name "DeepSeek Flash Latest"; DeepSeek documents `deepseek-flash` as served by V4.1-Flash-1017). The older `~deepseek/deepseek-v4-flash-latest` stays selectable.
- Free: `opencode/deepseek-v4.1-flash-free`.
- Muse: `opencode-go/muse-spark-1.3-contributor`.

No provider keys are stored or read. OpenRouter availability is the presence of the provider and model in the location catalog; budget problems are learned from the first failed response.

## Testing Decisions

Good tests assert externally observable behaviour: what model a session ends up on, what the policy decides for a given clock and catalog, what the interface shows for a given state. They do not assert private function names or JSX structure.

- **Policy, the primary seam:** a pure decision function taking clock, session, catalog, and cooldowns. Table-driven tests cover both Go windows, the exact boundary minutes, weekends, custom overnight-adjacent ranges, availability permutations, cooldown expiry, the all-unavailable case, and the off-peak return.
- **Error classification:** one table over status codes, messages, and repeat counts, asserting class, cooldown, and switch decision.
- **Configuration:** round-trip through the store, rejection of duplicate or unknown models, empty chain, overnight windows, and malformed time strings.
- **RPC contract:** `getState` shape, `updateConfig` round-trip, `resumeSession`, and `stateChanged` after an edit. Test the handlers directly; no HTTP needed.
- **TUI view model:** a pure projection from state plus catalog to rows, availability labels, and countdown text. No snapshot tests of rendered components.
- **Integration, one spike:** a throwaway plugin against a stub provider that returns `402` once. Assert from the request log that the first attempt used the OpenRouter model and the retry used Free, inside one turn, and that no second user prompt was needed. Record the result in `docs/spikes/`.
- **Prior art:** the repository is greenfield. Establish `bun test` (the host runtime is Bun) with pure modules under `src/policy/` and tests beside them; `tsc --noEmit` is the type gate.

## Out of Scope

- Browser or desktop interface. The interface is terminal-native.
- npm registry publication. Distribution is Git-only through `opencode plugin add github:...`.
- Storing, validating, or rotating provider API keys.
- Topping up OpenRouter or OpenCode balances, or predicting when a budget resets.
- Fetching pricing or peak schedules from the network at runtime. The Go preset is versioned data.
- Switching models after output has started.
- Managing sessions whose agent has an explicit model, and child/subagent sessions by default.
- Team or multi-user policy; configuration is per server, per user.
- Judging model quality; the chain order is the user's judgement.
- OpenRouter's native fallback-model routing; the cascade is plugin-side so it can cross providers.
- Desktop notifications or sounds.
- Windows beyond the Go preset are user-defined, not discovered.

## Further Notes

- Sources: OpenCode Go pricing/limits (<https://opencode.ai/v2/docs/console/go>), Console free models (<https://opencode.ai/v2/docs/console/models>), plugin hooks and RPC (<https://opencode.ai/v2/docs/build/plugins>, <https://opencode.ai/v2/docs/build/plugins/rpc>), TUI API (<https://opencode.ai/v2/docs/build/plugins/cli>). The Go schedule was verified on 2026-10-23; it is data, not a promise.
- Mechanic verified in the OpenCode source: `switchModel` projects `SessionTable.model` before the retry loop re-reads the session, and `Outcome.Retry` requires that no output has started. The spike exists to confirm the same holds through the plugin host at runtime.
- Muse Spark 1.3 Contributor trains on prompts and is unavailable in some regions, including Russia. It is deliberately last.
- DeepSeek V4.1 Flash Free is documented as zero-retention and not used for training; it is the cheapest safe step in the chain.
- The default chain costs money at step 1. A user who prefers free-first can reorder it without touching code.
