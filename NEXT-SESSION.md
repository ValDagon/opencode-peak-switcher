# Next session

Start here. The design is frozen; implementation begins with ticket 01.

## Read in this order

1. [`docs/spec.md`](docs/spec.md) — the whole design, including the verified runtime mechanics.
2. [`docs/adr/`](docs/adr/) — three decisions that explain why the shape is what it is.
3. [`docs/tickets/`](docs/tickets/) — the build order and the blocking edges.
4. [`GLOSSARY.md`](GLOSSARY.md) — use these words in code and UI.

## First command

There is nothing to install yet: the repository is docs-only, and ticket 02 creates the package scaffold. Start by reading the spec, then open ticket 01.

## Ticket order

```text
01 spike
  └─ 02 server policy
       ├─ 03 status surface
       │    ├─ 04 chain editor
       │    └─ 05 force + pinning
       └─ 06 error cascade
            └─ 07 GitHub distribution   (also needs 04 and 05)
```

## Facts to carry into the code

- Peak windows: `01:00–04:00` and `06:00–10:00` UTC, Monday–Friday. Weekends are off-peak.
- Model IDs are in the spec; the OpenRouter step is `~deepseek/deepseek-flash-latest`, not the older `~deepseek/deepseek-v4-flash-latest`.
- A `retry` hook may call `switchModel` and force `{ retry: true, delay: 0 }`; the runner re-reads the session model before the next attempt.
- `Outcome.Retry` only happens before output starts. Never plan a mid-stream switch.
- Provider availability comes from the catalog: disabled providers are excluded, and `auto` providers count when a connection exists. No key is needed.
- The retry hook has no `kind`; classify by status and message, not by request type.
- `ctx.storage` is a global key/value namespace, not location-scoped. RPC registration resolves to the most recently registered instance, so keep handlers location-agnostic.
- Distribution is Git-only: `opencode plugin add github:ValDagon/opencode-peak-switcher`. No npm publish; tags are the versions, and the manifest stays private.

## Known risk

The one thing the source reading cannot prove is the plugin-host round trip: `switchModel` called from inside a hook, observed by the immediately following attempt. Ticket 01 exists only to settle that, and nothing else should be built before it passes.
