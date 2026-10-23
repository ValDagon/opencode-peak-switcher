#!/usr/bin/env bash
# Run OpenCode against a disposable profile: its own config, database, cache and state.
# The real ~/.config/opencode and ~/.local/share/opencode are never touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB="${PEAK_LAB_DIR:-$HOME/.cache/opencode-peak-lab}"
CONFIG_DIR="$LAB/config/opencode"
PROJECT_DIR="$LAB/project"
PORT="${PEAK_FAKE_PORT:-8787}"
FORCE="${PEAK_FORCE:-auto}"

mkdir -p "$CONFIG_DIR" "$PROJECT_DIR" "$LAB/data" "$LAB/cache" "$LAB/state"

PLUGIN_PATH="${PEAK_PLUGIN_PATH:-}"
if [ -z "$PLUGIN_PATH" ] && [ -f "$ROOT/package.json" ]; then
  PLUGIN_PATH="$ROOT"
fi

PLUGIN_JSON=""
if [ -n "$PLUGIN_PATH" ]; then
  PLUGIN_JSON=$(cat <<JSON
  "plugins": [
    {
      "package": "$PLUGIN_PATH",
      "options": {
        "primary": { "providerID": "fake", "id": "one" },
        "chain": [
          { "id": "two", "model": { "providerID": "fake", "id": "two" }, "enabled": true },
          { "id": "three", "model": { "providerID": "fake", "id": "three" }, "enabled": true },
          { "id": "muse", "model": { "providerID": "fake", "id": "muse" }, "enabled": true }
        ],
        "force": "$FORCE"
      }
    }
  ],
JSON
)
fi

write_config() {
  cat > "$CONFIG_DIR/opencode.json" <<JSON
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "fake/one",
$PLUGIN_JSON
  "providers": {
    "fake": {
      "name": "Peak Lab Fake",
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": {
        "baseURL": "http://127.0.0.1:$PORT/v1",
        "apiKey": "lab"
      },
      "models": {
        "one": {
          "name": "Fake One",
          "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
          "limit": { "context": 128000, "output": 4096 },
          "cost": [{ "input": 0, "output": 0, "cache": { "read": 0, "write": 0 } }]
        },
        "two": {
          "name": "Fake Two",
          "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
          "limit": { "context": 128000, "output": 4096 },
          "cost": [{ "input": 0, "output": 0, "cache": { "read": 0, "write": 0 } }]
        },
        "three": {
          "name": "Fake Three",
          "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
          "limit": { "context": 128000, "output": 4096 },
          "cost": [{ "input": 0, "output": 0, "cache": { "read": 0, "write": 0 } }]
        },
        "muse": {
          "name": "Fake Muse",
          "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
          "limit": { "context": 128000, "output": 4096 },
          "cost": [{ "input": 0, "output": 0, "cache": { "read": 0, "write": 0 } }]
        }
      }
    }
  }
}
JSON
}

if [ ! -f "$CONFIG_DIR/opencode.json" ] || [ "${PEAK_LAB_RESET:-0}" = "1" ]; then
  write_config
fi

if [ "${1:-}" = "reset" ]; then
  rm -rf "$LAB/data" "$LAB/cache" "$LAB/state"
  mkdir -p "$LAB/data" "$LAB/cache" "$LAB/state"
  write_config
  echo "lab reset: $LAB"
  exit 0
fi

PEAK_FAKE_PORT="$PORT" bun "$ROOT/scripts/fake-provider.ts" &
FAKE_PID=$!
trap 'kill "$FAKE_PID" 2>/dev/null || true' EXIT

export XDG_CONFIG_HOME="$LAB/config"
export XDG_DATA_HOME="$LAB/data"
export XDG_CACHE_HOME="$LAB/cache"
export XDG_STATE_HOME="$LAB/state"

cat <<TEXT
Peak Switcher lab
  profile:  $LAB
  config:   $CONFIG_DIR/opencode.json
  data:     $LAB/data/opencode/opencode.db
  provider: http://127.0.0.1:$PORT/v1
  plugin:   ${PLUGIN_PATH:-none}
  force:    $FORCE

The real OpenCode profile is not used. Do not run 'opencode plugin add' here.
TEXT

cd "$PROJECT_DIR"
if [ "${1:-}" = "run" ]; then
  shift
  opencode run --standalone "$@"
else
  opencode --standalone "$@"
fi
