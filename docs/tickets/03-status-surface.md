# 03: Status surface

**What to build:** The read-only half of the interface: a compact status indicator in the prompt and home footers, and a `/peak` page showing force mode, local time, the next boundary, the primary model, every candidate with its availability reason, pinned sessions, and the last switch with its cause. Live countdown; no editing yet.

**Blocked by:** 02.

**Status:** ready-for-agent

- [ ] The footer shows `PEAK` or `OFF-PEAK`, a countdown, and the effective model.
- [ ] `/peak` opens a page that renders the full state for the current location.
- [ ] Availability is computed from the TUI's own catalog, not from RPC.
- [ ] The page reflects a switch that happened while it was open.
- [ ] The view model is tested without rendering JSX.
