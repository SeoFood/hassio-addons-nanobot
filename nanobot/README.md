# Home Assistant Add-on: Nanobot

This add-on packages [Nanobot](https://github.com/HKUDS/nanobot) and runs its gateway service.

## Features

- Multi-arch build target: `amd64`, `aarch64`
- Gateway mode with HTTP API on port 18790
- Minimal add-on UI - only `persistent_data_dir` to configure
- Full Nanobot configuration via `config.json` (provider, channels, tools, MCP servers, etc.)
- Built-in WhatsApp bridge (auto-started when enabled in config.json)
- Configurable persistent data directory (default `/share/nanobot`)

See `DOCS.md` for configuration details.
