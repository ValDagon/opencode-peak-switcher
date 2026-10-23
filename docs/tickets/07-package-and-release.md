# 07: Package, install, docs, release

**What to build:** The shippable form. One npm package exporting `.`, `./rpc`, and `./tui`; peer dependencies for the TUI; `opencode plugin add` works from a packed tarball; README with the install command, the default chain, the privacy note about Muse, and screenshots of the page. CI runs typecheck and tests. MIT license. A release workflow that publishes to npm with provenance once the maintainer supplies an `NPM_TOKEN`.

**Blocked by:** 04, 05, 06.

**Status:** ready-for-agent

- [ ] `npm pack` produces a tarball that installs with `opencode plugin add ./opencode-peak-switcher-<version>.tgz`.
- [ ] Both entrypoints load in a live OpenCode and the page opens.
- [ ] README instructions work on a clean machine.
- [ ] CI is green on typecheck and tests.
- [ ] The package contains no provider keys and no `.scratch` or spike code.
- [ ] The release workflow is documented; the first publish is the maintainer's manual step.
