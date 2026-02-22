# Home Assistant Add-on: Nanobot

This add-on packages [Nanobot](https://github.com/HKUDS/nanobot) and runs its gateway service.

## Features

- Multi-arch build target: `amd64`, `aarch64`
- Gateway mode with HTTP API on port 18790
- Telegram, Discord, and WhatsApp channels configurable via add-on UI
- Built-in WhatsApp bridge (auto-started when enabled)
- Advanced channels (Feishu, DingTalk, Slack, QQ, Email, Mochat) via manual config.json editing
- Configurable persistent data directory via `persistent_data_dir` (use `/share/...` for easy backup/restore)
- Config merge: add-on UI keys are applied on every start, manual keys are preserved

See `DOCS.md` for configuration details.
