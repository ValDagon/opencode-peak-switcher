# 07: Distribute from GitHub

**What to build:** The shippable form, distributed straight from the repository with no npm publication. One package exporting `.`, `./rpc`, and `./tui`; peer dependencies for the TUI; `opencode plugin add github:ValDagon/opencode-peak-switcher` works on a clean machine; README with the install command, tag pinning, the default chain, the privacy note about Muse, and screenshots of the page. CI runs typecheck and tests. MIT license. A dated tag marks the first usable release.

**Blocked by:** 04, 05, 06.

**Status:** ready-for-agent

- [ ] `opencode plugin add github:ValDagon/opencode-peak-switcher` installs on a clean machine and loads both entrypoints.
- [ ] A pinned install (`#v0.1.0`) resolves to that tag and does not move when the branch advances.
- [ ] An unpinned install is refreshed by `opencode plugin update`.
- [ ] Dependencies install correctly from a Git checkout, including the TUI peers.
- [ ] The package contains no provider keys and no spike code.
- [ ] CI is green on typecheck and tests.
- [ ] README instructions, including the local-path install for development, work as written.
- [ ] The package manifest is private, so no accidental npm publish is possible.
