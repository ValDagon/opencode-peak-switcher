# 04: Chain editor

**What to build:** Full editing of the fallback chain from `/peak`: reorder, add, remove, enable or disable, and pick models by display name from a searchable catalog. The picker offers only tool-capable text models, grouped by provider, and warns when a candidate's context window is smaller than the session's current usage. Every edit persists immediately.

**Blocked by:** 03.

**Status:** ready-for-agent

- [ ] Reordering a candidate changes which model the next peak turn uses.
- [ ] Add opens a searchable picker; selecting a model appends it and the chain renders it.
- [ ] Models without tool support are not offered.
- [ ] A smaller-context candidate is marked with a warning before it is added.
- [ ] Removing or disabling the last candidate leaves the primary as the documented last resort.
- [ ] Edits survive a restart.
