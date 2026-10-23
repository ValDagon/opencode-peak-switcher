# One package, two entrypoints: server policy and TUI control surface

**Status:** accepted

A server plugin cannot draw anything, and a TUI plugin cannot own session policy. We ship a single package with `.` (policy, config, hooks, RPC) and `./tui` (status slot, `/peak` page, editors), plus `./rpc` for the shared contract. The server owns the source of truth in plugin storage; the TUI is a view and controller over RPC. Model availability is rendered from the TUI's own location catalog, because RPC registrations resolve to the most recently registered plugin instance and are therefore not safely location-scoped.

## Consequences

- One install command and one version to keep in sync.
- Distribution is Git-only (`opencode plugin add github:ValDagon/opencode-peak-switcher`); the repository is the registry, and tags are the versions.
- The TUI is useless without the server entrypoint, which is why they ship together.
- RPC handlers must stay location-agnostic: config and runtime state only, never "the models available in this project".
