# Nanobot Add-on Test Playbook (Home Assistant)

## Goal

Verify that the `nanobot` add-on installs and runs correctly on `amd64` and `aarch64`, using gateway mode.

## Prerequisites

- Home Assistant OS with Supervisor
- Access to the Add-on Store
- This repository added as an add-on source
- A valid LLM API key (for example OpenRouter, OpenAI, or Anthropic)

## 1. Add repository

1. Open Add-on Store.
2. Open the top-right menu and select Repositories.
3. Add `https://github.com/SeoFood/hassio-addons-nanobot`.
4. Save and reload the store.

## 2. Install add-on

1. Open add-on `Nanobot`.
2. Install it.
3. Do not start yet; set config first.

## 3. Base configuration

Use this configuration:

```yaml
provider: openrouter
api_key: "<YOUR_API_KEY>"
persistent_data_dir: nanobot
```

Note: `api_key` is required. The add-on exits by design when it is missing.

## 4. Start and log checks

1. Start the add-on.
2. Check logs. Expected:
   - `Nanobot Add-on`
   - `Runtime mode: gateway`
   - `State dir: /share/nanobot` (if `persistent_data_dir: nanobot`)
   - no immediate crash/exit
3. Confirm config exists:
   - `/share/nanobot/.nanobot/config.json`
   - `/share/nanobot/workspace/AGENTS.md`

## 5. Telegram functional test

1. Set configuration:

```yaml
telegram_enabled: true
telegram_token: "<YOUR_BOT_TOKEN>"
telegram_allow_from:
  - "<YOUR_USER_ID>"
```

2. Restart the add-on.
3. Send a test message to the bot.
4. Expected:
   - bot responds
   - no provider/auth errors in logs

## 6. Discord functional test

1. Set configuration:

```yaml
discord_enabled: true
discord_token: "<YOUR_BOT_TOKEN>"
discord_allow_from:
  - "<YOUR_USER_ID>"
```

2. Restart the add-on.
3. Send a test message to the bot.
4. Expected:
   - bot responds
   - no provider/auth errors in logs

## 7. WhatsApp functional test

1. Set configuration:

```yaml
whatsapp_enabled: true
whatsapp_allow_from:
  - "<YOUR_PHONE_NUMBER>"
```

2. Restart the add-on.
3. Check logs for QR code.
4. Scan QR code with WhatsApp.
5. Send a test message.
6. Expected:
   - bridge starts successfully
   - bot responds after pairing

## 8. Persistence test

1. Configure a channel and verify it works.
2. Stop the add-on.
3. Restart Home Assistant.
4. Start the add-on again.
5. Expected:
   - startup still succeeds
   - state in `/share/nanobot` is preserved (config, workspace, WhatsApp auth)
   - channel still works without re-pairing (WhatsApp)

## 9. Config merge test

1. Edit `/share/nanobot/.nanobot/config.json` and add a custom key:

```json
{
    "tools": {
        "web": {
            "search": {
                "apiKey": "test-brave-key"
            }
        }
    }
}
```

2. Restart the add-on.
3. Verify the custom key is preserved in config.json after restart.

## 10. Negative tests

- `api_key` empty: add-on must fail with a clear error.
- Invalid `provider`: add-on starts, but provider errors appear during requests.
- Invalid `telegram_token`: add-on starts, but Telegram channel errors appear in logs.

## 11. Architecture matrix

Run at least once on:

- `amd64` (for example x86 mini PC or VM)
- `aarch64` (for example Raspberry Pi 4/5 64-bit)

## 12. Acceptance criteria

- Installation successful
- Start successful
- Gateway API reachable on port 18790
- Telegram/Discord channel flow works
- WhatsApp bridge starts and pairs
- Persistence works across restart/reboot
- Config merge preserves manual keys
- No regressions on `amd64` and `aarch64`
