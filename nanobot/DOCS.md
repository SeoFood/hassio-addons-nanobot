# Nanobot

Run the Nanobot AI agent as a Home Assistant add-on.

## Configuration

### Required

- `provider` (required): LLM provider name (`openrouter`, `anthropic`, `openai`, `deepseek`, `groq`, `gemini`, ...)
- `api_key` (required): API key for your provider

### Optional

- `model`: Explicit model override (e.g. `anthropic/claude-sonnet-4-20250514`). Leave empty to use the provider default.
- `persistent_data_dir`: Folder for all persistent add-on data (config, workspace, WhatsApp auth). Relative paths resolve under `/share`.

### Telegram

- `telegram_enabled`: Enable Telegram channel
- `telegram_token`: Bot token from @BotFather
- `telegram_allow_from`: List of allowed Telegram user IDs or usernames

### Discord

- `discord_enabled`: Enable Discord channel
- `discord_token`: Bot token from the Discord Developer Portal
- `discord_allow_from`: List of allowed Discord user IDs

### WhatsApp

- `whatsapp_enabled`: Enable WhatsApp channel (uses built-in bridge)
- `whatsapp_allow_from`: List of allowed phone numbers

## Quick start

1. Install the add-on.
2. Set your provider and API key in the configuration tab:

```yaml
provider: openrouter
api_key: "sk-or-v1-..."
persistent_data_dir: nanobot
```

3. Start the add-on.
4. Check the logs for the startup banner.

## Telegram setup

1. Create a bot via [@BotFather](https://t.me/BotFather) and copy the token.
2. Get your Telegram user ID (e.g. via [@userinfobot](https://t.me/userinfobot)).
3. Configure:

```yaml
telegram_enabled: true
telegram_token: "123456:ABC-DEF..."
telegram_allow_from:
  - "your_user_id"
```

4. Restart the add-on.

## Discord setup

1. Create a bot in the [Discord Developer Portal](https://discord.com/developers/applications).
2. Enable the Message Content Intent.
3. Copy the bot token and add the bot to your server.
4. Configure:

```yaml
discord_enabled: true
discord_token: "your-bot-token"
discord_allow_from:
  - "your_discord_user_id"
```

5. Restart the add-on.

## WhatsApp setup

1. Enable WhatsApp in the configuration:

```yaml
whatsapp_enabled: true
whatsapp_allow_from:
  - "+1234567890"
```

2. Start the add-on and check the logs for a QR code.
3. Scan the QR code with WhatsApp on your phone.

## Advanced configuration

For additional channels (Feishu, DingTalk, Slack, QQ, Email, Mochat) and advanced tools (MCP servers, web search), edit the config file directly:

```
/share/nanobot/.nanobot/config.json
```

Keys you add manually are preserved across add-on restarts. Only keys managed by the add-on UI (provider, channels, gateway) are overwritten.

For the full configuration schema, see the [Nanobot documentation](https://github.com/HKUDS/nanobot).

## Notes

- Default persistent data path is `/data/nanobot`.
- If `persistent_data_dir` is set, data is stored there instead (e.g. `/share/nanobot`).
- On first start with `persistent_data_dir`, existing data from `/data/nanobot` is auto-migrated when the target folder is empty.
- The add-on runs Nanobot in gateway mode with an HTTP API on port 18790.
- The gateway port can be exposed via the Network section in the add-on settings.

## Security

- Always set `allow_from` lists for your channels to restrict who can interact with the bot.
- Avoid leaving `allow_from` empty in production - this allows anyone to use the bot.
