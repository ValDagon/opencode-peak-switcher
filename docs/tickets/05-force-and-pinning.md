# 05: Force mode, pinning, and resume

**What to build:** Operator control over the clock and over individual sessions. Auto / Force Peak / Force Off-Peak from the page and a palette command. A manual model choice pins the session and stops the policy from touching it; the page lists pinned sessions and offers "Resume auto", which returns the session to the policy on its next prompt. Agent-configured sessions are treated as pinned.

**Blocked by:** 03.

**Status:** ready-for-agent

- [ ] Switching force mode flips the effective model on the next prompt.
- [ ] Choosing a model with `/models` pins the session; the next prompt is not overridden.
- [ ] A command that selects its own model pins the session.
- [ ] The page shows the session as pinned with the model the user chose.
- [ ] "Resume auto" clears the pin and the next prompt applies the policy.
- [ ] "Adopt this session" takes ownership of an outside-the-set session and records its current model as the origin.
- [ ] A session whose agent has an explicit model is never switched.
- [ ] Pin detection has table-driven tests for first sight, user change, command change, agent model, and plugin-initiated change.
