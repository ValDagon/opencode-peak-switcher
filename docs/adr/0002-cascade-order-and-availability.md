# Order the cascade OpenRouter → Free → Muse, and read availability from the catalog

**Status:** accepted

At peak we prefer the same model family on a paid route first (`openrouter/~deepseek/deepseek-flash-latest`), then the free OpenCode route, and only then a different model (`opencode-go/muse-spark-1.3-contributor`). Availability is decided without credentials: a candidate is usable when its provider appears in the location's provider catalog and the model is enabled there. Budget exhaustion is learned from observed `402`/`403` responses, not from a stored OpenRouter key. Muse stays last because its Contributor tier trains on prompts and is unavailable in some regions.

## Consequences

- The plugin cannot show an OpenRouter balance before the first failure. The first `402` costs one failed attempt, then the turn continues on Free.
- A connected OpenRouter account with a zero balance still looks available until it fails.
- The OpenRouter model is the current `deepseek-flash` alias, which DeepSeek documents as served by V4.1-Flash-1017. The older `~deepseek/deepseek-v4-flash-latest` remains selectable.
