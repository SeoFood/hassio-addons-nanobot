# Nanobot

Run the Nanobot AI agent as a Home Assistant add-on.

## Configuration

### Add-on UI

The add-on has a single configuration option:

- `persistent_data_dir`: Folder for all persistent add-on data (config, workspace, WhatsApp auth). Relative paths resolve under `/share`. Default: `nanobot` (i.e. `/share/nanobot`).

### config.json

All Nanobot settings (provider, API key, model, channels, tools, etc.) are configured directly in:

```
/share/nanobot/.nanobot/config.json
```

On first start, a minimal config.json is created with gateway defaults. Edit this file to add your provider, API key, channels, and any other settings.

For the full configuration schema, see the [Nanobot documentation](https://github.com/HKUDS/nanobot).

## Quick start

1. Install the add-on.
2. Set `persistent_data_dir` (default `nanobot` is fine).
3. Start the add-on.
4. Edit `/share/nanobot/.nanobot/config.json` to add your provider and API key:

```json
{
    "providers": {
        "openrouter": {
            "apiKey": "sk-or-v1-..."
        }
    },
    "gateway": {
        "host": "0.0.0.0",
        "port": 18790
    }
}
```

5. Restart the add-on.

## Channel setup

All channels are configured in `config.json`. Examples:

### Telegram

```json
{
    "channels": {
        "telegram": {
            "enabled": true,
            "token": "123456:ABC-DEF...",
            "allowFrom": ["your_user_id"]
        }
    }
}
```

### Discord

```json
{
    "channels": {
        "discord": {
            "enabled": true,
            "token": "your-bot-token",
            "allowFrom": ["your_discord_user_id"]
        }
    }
}
```

### WhatsApp

```json
{
    "channels": {
        "whatsapp": {
            "enabled": true,
            "bridgeUrl": "ws://127.0.0.1:3001",
            "allowFrom": ["+1234567890"]
        }
    }
}
```

The WhatsApp bridge is auto-started when `channels.whatsapp.enabled` is `true` in config.json. Check the logs for a QR code on first pairing.

## Notes

- Default persistent data path is `/share/nanobot` (when `persistent_data_dir: nanobot`).
- On first start, `nanobot onboard` runs to create default config and workspace files.
- The add-on runs Nanobot in gateway mode with an HTTP API on port 18790.
- The gateway port can be exposed via the Network section in the add-on settings.
- Gateway defaults (`host: 0.0.0.0`, `port: 18790`) are injected automatically so the container is always reachable.

## Security

- Always set `allowFrom` lists for your channels to restrict who can interact with the bot.
- Avoid leaving `allowFrom` empty in production - this allows anyone to use the bot.
