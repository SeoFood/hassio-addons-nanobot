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
3. Do not start yet; check config first.

## 3. Base configuration

The only HA UI option is `persistent_data_dir` (default: `nanobot`). Keep the default or change it.

```yaml
persistent_data_dir: nanobot
```

## 4. First start

1. Start the add-on.
2. Check logs. Expected:
   - `Nanobot Add-on`
   - `State dir: /share/nanobot`
   - `Runtime mode: gateway`
   - `First start - running onboard to initialize workspace`
   - no immediate crash/exit
3. Confirm files exist:
   - `/share/nanobot/.nanobot/config.json`
   - `/share/nanobot/workspace/AGENTS.md`

## 5. Configure provider

1. Stop the add-on.
2. Edit `/share/nanobot/.nanobot/config.json`:

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

3. Start the add-on.
4. Verify gateway is reachable on port 18790.

## 6. Telegram functional test

1. Edit `/share/nanobot/.nanobot/config.json` and add:

```json
{
    "channels": {
        "telegram": {
            "enabled": true,
            "token": "<YOUR_BOT_TOKEN>",
            "allowFrom": ["<YOUR_USER_ID>"]
        }
    }
}
```

2. Restart the add-on.
3. Send a test message to the bot.
4. Expected:
   - bot responds
   - no provider/auth errors in logs

## 7. Discord functional test

1. Edit `/share/nanobot/.nanobot/config.json` and add:

```json
{
    "channels": {
        "discord": {
            "enabled": true,
            "token": "<YOUR_BOT_TOKEN>",
            "allowFrom": ["<YOUR_USER_ID>"]
        }
    }
}
```

2. Restart the add-on.
3. Send a test message to the bot.
4. Expected:
   - bot responds
   - no provider/auth errors in logs

## 8. WhatsApp functional test

1. Edit `/share/nanobot/.nanobot/config.json` and add:

```json
{
    "channels": {
        "whatsapp": {
            "enabled": true,
            "bridgeUrl": "ws://127.0.0.1:3001",
            "allowFrom": ["<YOUR_PHONE_NUMBER>"]
        }
    }
}
```

2. Restart the add-on.
3. Check logs for QR code.
4. Scan QR code with WhatsApp.
5. Send a test message.
6. Expected:
   - bridge starts successfully
   - bot responds after pairing

## 9. Persistence test

1. Configure a channel and verify it works.
2. Stop the add-on.
3. Restart Home Assistant.
4. Start the add-on again.
5. Expected:
   - startup still succeeds
   - state in `/share/nanobot` is preserved (config, workspace, WhatsApp auth)
   - channel still works without re-pairing (WhatsApp)

## 10. Gateway defaults test

1. Remove the `gateway` key from config.json.
2. Restart the add-on.
3. Verify that gateway defaults (`host: 0.0.0.0`, `port: 18790`) are injected automatically.
4. Verify gateway is reachable on port 18790.

## 11. Negative tests

- No provider configured in config.json: add-on starts, but provider errors appear during requests.
- Invalid channel token: add-on starts, but channel errors appear in logs.

## 12. Architecture matrix

Run at least once on:

- `amd64` (for example x86 mini PC or VM)
- `aarch64` (for example Raspberry Pi 4/5 64-bit)

## 13. Acceptance criteria

- Installation successful
- Start successful (even without provider config)
- Gateway API reachable on port 18790
- Telegram/Discord channel flow works (when configured in config.json)
- WhatsApp bridge starts and pairs (when enabled in config.json)
- Persistence works across restart/reboot
- Gateway defaults are injected when missing
- Only 1 option visible in HA add-on UI (`persistent_data_dir`)
- No regressions on `amd64` and `aarch64`
