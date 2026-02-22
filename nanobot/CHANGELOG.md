# Changelog

## 0.1.4-2

- Simplified add-on configuration: only `persistent_data_dir` remains as HA UI option (default: `nanobot`).
- Removed provider, api_key, model, telegram, discord, and whatsapp options from add-on UI.
- All Nanobot settings are now configured directly in `config.json`.
- run.sh no longer generates config.json - only injects gateway defaults (`host: 0.0.0.0`, `port: 18790`).
- WhatsApp bridge activation now reads from `channels.whatsapp.enabled` in config.json.
- First start runs `nanobot onboard` to create default config and workspace.

## 0.1.4-1

- Initial Home Assistant add-on for Nanobot.
- Multi-arch setup for `aarch64` and `amd64`.
- Gateway mode with HTTP API on port 18790.
- Telegram, Discord, and WhatsApp channels configurable via add-on UI.
- WhatsApp bridge built and managed automatically.
- Persistent data directory support with auto-migration.
- Config merge strategy: add-on UI keys overwrite, manual keys are preserved.
