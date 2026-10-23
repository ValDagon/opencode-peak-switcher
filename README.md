# Peak Switcher for OpenCode

An OpenCode plugin that moves sessions along a user-editable fallback chain when DeepSeek's peak pricing starts, and moves them back when it ends.

> **Status:** design complete, implementation starts with [`docs/tickets/01-spike-in-turn-fallback.md`](docs/tickets/01-spike-in-turn-fallback.md). Not installable yet.

## The problem

DeepSeek V4.1 Flash costs twice as much during peak hours. On OpenCode Go those hours are **01:00–04:00 and 06:00–10:00 UTC, Monday through Friday**; everything else, including weekends, is off-peak. Remembering to switch models by hand — and switching back — is tedium that costs money when forgotten.

## The default policy

| Moment | Model |
| --- | --- |
| Off-peak | `opencode-go/deepseek-v4.1-flash` |
| Peak, step 1 | `openrouter/~deepseek/deepseek-flash-latest` |
| Peak, step 2 | `opencode/deepseek-v4.1-flash-free` |
| Peak, step 3 | `opencode-go/muse-spark-1.3-contributor` |
| Nothing available | the primary model, with a visible reason |

The chain is a default, not a rule. Every step and the order are editable from the `/peak` page.

## How it works

- Before each turn, the plugin computes the model the policy wants and switches the session if needed.
- If a provider turns out to be unusable — no OpenRouter budget, exhausted free limits, a model that disappeared — the plugin switches to the next candidate and retries **inside the same turn**, before any output is produced.
- Choosing a model manually pins the session. The plugin stops touching it until you choose **Resume auto**.
- No provider API keys are stored. OpenRouter availability comes from OpenCode's own provider catalog; budget failures are learned from the first failed response.

## Install

The plugin is distributed directly from GitHub — there is no npm package.

```sh
opencode plugin add github:ValDagon/opencode-peak-switcher
```

Pin a tag or commit for a reproducible install:

```sh
opencode plugin add github:ValDagon/opencode-peak-switcher#v0.1.0
```

Unpinned installs can be refreshed with `opencode plugin update`; pinned ones are updated by re-adding a newer tag.

Then run `/peak` in OpenCode.

## Privacy

The default chain tries the paid route first, then OpenCode's free DeepSeek route (documented as zero-retention and not used for training), and only then **Muse Spark 1.3 Contributor**, whose Contributor tier trains on prompts and is unavailable in some regions, including Russia. Reorder the chain if that trade-off is not acceptable.

## Development

The package scaffold lands with ticket 02. From then on:

```sh
bun install
bun test
bunx tsc --noEmit
```

Installing into OpenCode straight from the working copy is also supported while developing:

```sh
opencode plugin add /absolute/path/to/opencode-peak-switcher
```

The design lives in [`docs/spec.md`](docs/spec.md), the decisions in [`docs/adr/`](docs/adr/), and the vocabulary in [`GLOSSARY.md`](GLOSSARY.md).

## License

MIT
