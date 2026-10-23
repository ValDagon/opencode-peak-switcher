# Peak Switcher

An OpenCode plugin that moves sessions between models according to time-of-day pricing and provider availability, without breaking the conversation.

## Language

**Peak window**:
The UTC intervals when the primary model is billed at its peak rate: 01:00–04:00 and 06:00–10:00, Monday through Friday.
_Avoid_: busy hours, rush hour

**Off-peak**:
Every instant outside a peak window, including all weekend hours.
_Avoid_: free hours, discount window

**Primary model**:
The model a session uses by default, outside peak windows.
_Avoid_: base model, default model

**Fallback chain**:
The ordered list of candidates a session may move to, first available wins.
_Avoid_: model list, cascade

**Candidate**:
One step in the fallback chain: a model reference plus its current availability.
_Avoid_: fallback model, backup

**Effective model**:
The model a managed session will use for its next request.
_Avoid_: current model

**Managed session**:
A session whose effective model is chosen by the plugin.
_Avoid_: auto session

**Pinned session**:
A session the user has taken over by choosing a model manually; the plugin stops changing it until the user resumes automatic control.
_Avoid_: manual session, locked session

**Turn**:
One user prompt and everything the agent does until it goes idle again.
_Avoid_: message, request

**In-turn fallback**:
Moving to the next candidate and retrying the failed model call inside the same turn, before any output has been produced.
_Avoid_: retry, auto-switch

**Cooldown**:
A period during which a candidate is treated as unavailable after an observed failure, without probing it again.
_Avoid_: backoff

**Force mode**:
An operator setting that overrides the clock: Auto, Force Peak, or Force Off-Peak.
_Avoid_: override, manual mode
