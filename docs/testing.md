# Testing without touching your OpenCode

The lab runs a **private server** with its own config, database, cache, and state. Your daily profile at `~/.config/opencode` and `~/.local/share/opencode` is not used.

## One command

```sh
./scripts/lab.sh run "Say ok in three words"
```

This creates `~/.cache/opencode-peak-lab`, starts a fake OpenAI-compatible provider, points every XDG directory at the lab, and runs `opencode run --standalone`.

For the interactive interface:

```sh
./scripts/lab.sh
```

## What is isolated

| Thing | Where it lives in the lab |
| --- | --- |
| Config | `~/.cache/opencode-peak-lab/config/opencode/opencode.json` |
| Sessions and database | `~/.cache/opencode-peak-lab/data/opencode/opencode.db` |
| Cache and state | `~/.cache/opencode-peak-lab/{cache,state}` |
| Server process | private, started by `--standalone` |
| Provider | `scripts/fake-provider.ts` on `127.0.0.1:8787` |

The OpenCode binary and this repository are shared; nothing else is.

## What not to do

- **Never run `opencode plugin add` for a test.** It writes the real global config. Use the lab config, which lists the plugin by absolute path.
- **Do not trust CLI commands without `--standalone`.** `opencode debug config`, `plugin list`, and `models` talk to the shared background service, which still runs your real config. That is why `debug config` shows the real file even with the XDG variables set.
- **Do not expect real credentials in the lab.** Its data directory is empty; the fake provider needs none.

## Test the plugin

When the package has a `package.json`, `lab.sh` adds it to the scratch config automatically and pre-seeds the fake chain:

```text
primary  fake/one
chain    fake/two -> fake/three -> fake/muse
```

For the spike, point the script at the spike package:

```sh
PEAK_PLUGIN_PATH=/absolute/path/to/spike ./scripts/lab.sh
```

## Failure injection

```sh
PEAK_FAIL_MODEL=one PEAK_FAIL_STATUS=402 ./scripts/lab.sh run "Say ok"
```

The first request to `fake/one` returns an OpenRouter-shaped error; a working cascade should still answer from `fake/two`. The fake provider logs every attempt as JSON.

- `402` / `403` — budget
- `429` — rate limit
- `404` — model unavailable

`PEAK_FAIL_TIMES` controls how many requests fail before the model recovers.

## Force the clock

```sh
PEAK_FORCE=peak ./scripts/lab.sh run "Say ok"
```

Accepted values: `auto`, `peak`, `off-peak`.

## Reset

```sh
./scripts/lab.sh reset
```

Deletes the lab database, cache, and state, then regenerates the config.

## Prove the real profile is untouched

Every lab session is written to the lab database only:

```sh
sqlite3 ~/.cache/opencode-peak-lab/data/opencode/opencode.db \
  "select id, title, model from session_v2 order by time_created desc limit 3;"
```

Take an ID from that output and check the real database:

```sh
sqlite3 ~/.local/share/opencode/opencode.db \
  "select count(*) from session_v2 where id='<lab-session-id>';"
```

It must return `0`.

## Use a different lab

```sh
PEAK_LAB_DIR=/tmp/peak-lab-alt PEAK_FAKE_PORT=8788 ./scripts/lab.sh
```

Each lab directory is a complete, disposable profile.
