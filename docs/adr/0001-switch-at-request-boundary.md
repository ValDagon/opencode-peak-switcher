# Switch models at request boundaries, never mid-request

**Status:** accepted

OpenCode's session hooks expose the request model as readonly, so a plugin cannot swap the model inside an in-flight call. The runner does, however, re-read the session's model from the store before every retry attempt, and the prompt hook runs before model resolution. We therefore switch in exactly two places: the `prompt` hook for planned moves (peak starts or ends), and the `retry` hook for in-turn fallback, where we change the session model and force an immediate retry. Consequences: a window that opens mid-request waits for the next turn, and a failure after output has started is surfaced rather than silently retried on another model.

## Considered Options

- Rewriting the outgoing HTTP request to point at another provider. Rejected: it defeats OpenCode's model resolution, breaks cost accounting and transcript attribution, and the model reference the runner records would be wrong.
- Switching only between turns. Rejected: a dead OpenRouter balance would still fail the user's current prompt instead of falling through to Free.
