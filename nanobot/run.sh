#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
DEFAULT_STATE_DIR="/data/nanobot"
STATE_DIR="${DEFAULT_STATE_DIR}"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

read_opt() {
    local key="$1"
    local default="${2:-}"

    if [[ -f "${OPTIONS_FILE}" ]]; then
        local value
        value="$(jq -r "${key} // empty" "${OPTIONS_FILE}" 2>/dev/null || true)"
        if [[ -n "${value}" ]]; then
            echo "${value}"
            return
        fi
    fi

    echo "${default}"
}

resolve_path() {
    local value="$1"
    if [[ "${value}" != /* ]]; then
        echo "/share/${value}"
        return
    fi
    echo "${value}"
}

dir_has_entries() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        return 1
    fi
    find "${dir}" -mindepth 1 -maxdepth 1 -print -quit | grep -q .
}

# ---------------------------------------------------------------------------
# Read HA options
# ---------------------------------------------------------------------------

API_KEY="$(read_opt '.api_key' '')"
PROVIDER="$(read_opt '.provider' 'openrouter')"
MODEL="$(read_opt '.model' '')"
PERSISTENT_DATA_DIR="$(read_opt '.persistent_data_dir' '')"

TELEGRAM_ENABLED="$(read_opt '.telegram_enabled' 'false')"
TELEGRAM_TOKEN="$(read_opt '.telegram_token' '')"

DISCORD_ENABLED="$(read_opt '.discord_enabled' 'false')"
DISCORD_TOKEN="$(read_opt '.discord_token' '')"

WHATSAPP_ENABLED="$(read_opt '.whatsapp_enabled' 'false')"

# ---------------------------------------------------------------------------
# Validate required fields
# ---------------------------------------------------------------------------

if [[ -z "${API_KEY}" ]]; then
    echo "ERROR: Option 'api_key' is missing or empty." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve state directory + migration
# ---------------------------------------------------------------------------

if [[ "${PERSISTENT_DATA_DIR}" == "null" ]]; then
    PERSISTENT_DATA_DIR=""
fi
if [[ -n "${PERSISTENT_DATA_DIR}" ]]; then
    STATE_DIR="$(resolve_path "${PERSISTENT_DATA_DIR}")"
    STATE_DIR="${STATE_DIR%/}"
fi

mkdir -p "${STATE_DIR}"
if [[ "${STATE_DIR}" != "${DEFAULT_STATE_DIR}" ]]; then
    if dir_has_entries "${DEFAULT_STATE_DIR}" && ! dir_has_entries "${STATE_DIR}"; then
        cp -a "${DEFAULT_STATE_DIR}/." "${STATE_DIR}/"
        echo "INFO: Migrated persistent data from ${DEFAULT_STATE_DIR} to ${STATE_DIR}." >&2
    fi
fi

mkdir -p "${STATE_DIR}/.nanobot" "${STATE_DIR}/workspace"

export HOME="${STATE_DIR}"

# ---------------------------------------------------------------------------
# Read allow_from arrays from HA options
# ---------------------------------------------------------------------------

TELEGRAM_ALLOW_FROM="$(jq -c '.telegram_allow_from // []' "${OPTIONS_FILE}" 2>/dev/null || echo '[]')"
DISCORD_ALLOW_FROM="$(jq -c '.discord_allow_from // []' "${OPTIONS_FILE}" 2>/dev/null || echo '[]')"
WHATSAPP_ALLOW_FROM="$(jq -c '.whatsapp_allow_from // []' "${OPTIONS_FILE}" 2>/dev/null || echo '[]')"

# ---------------------------------------------------------------------------
# Generate config.json (merge strategy: HA keys overwrite, user keys preserved)
# ---------------------------------------------------------------------------

CONFIG_FILE="${STATE_DIR}/.nanobot/config.json"

# Build HA-managed config fragment
HA_CONFIG="$(jq -n \
    --arg provider "${PROVIDER}" \
    --arg api_key "${API_KEY}" \
    --arg model "${MODEL}" \
    --arg workspace "${STATE_DIR}/workspace" \
    --argjson telegram_enabled "${TELEGRAM_ENABLED}" \
    --arg telegram_token "${TELEGRAM_TOKEN}" \
    --argjson telegram_allow_from "${TELEGRAM_ALLOW_FROM}" \
    --argjson discord_enabled "${DISCORD_ENABLED}" \
    --arg discord_token "${DISCORD_TOKEN}" \
    --argjson discord_allow_from "${DISCORD_ALLOW_FROM}" \
    --argjson whatsapp_enabled "${WHATSAPP_ENABLED}" \
    --argjson whatsapp_allow_from "${WHATSAPP_ALLOW_FROM}" \
    '{
        providers: {
            ($provider): {
                apiKey: $api_key
            }
        },
        agents: {
            defaults: ({
                workspace: $workspace
            } + if $model != "" and $model != "null" then { model: $model } else {} end)
        },
        channels: {
            telegram: ({
                enabled: $telegram_enabled
            } + if $telegram_token != "" and $telegram_token != "null" then { token: $telegram_token } else {} end
              + if ($telegram_allow_from | length) > 0 then { allowFrom: $telegram_allow_from } else {} end),
            discord: ({
                enabled: $discord_enabled
            } + if $discord_token != "" and $discord_token != "null" then { token: $discord_token } else {} end
              + if ($discord_allow_from | length) > 0 then { allowFrom: $discord_allow_from } else {} end),
            whatsapp: ({
                enabled: $whatsapp_enabled,
                bridgeUrl: "ws://127.0.0.1:3001"
            } + if ($whatsapp_allow_from | length) > 0 then { allowFrom: $whatsapp_allow_from } else {} end)
        },
        gateway: {
            host: "0.0.0.0",
            port: 18790
        }
    }'
)"

if [[ -f "${CONFIG_FILE}" ]]; then
    # Merge: existing config as base, HA config overwrites
    MERGED="$(jq -s '.[0] * .[1]' "${CONFIG_FILE}" <(echo "${HA_CONFIG}"))"
    echo "${MERGED}" > "${CONFIG_FILE}"
else
    echo "${HA_CONFIG}" > "${CONFIG_FILE}"
fi

chmod 600 "${CONFIG_FILE}" || true

# ---------------------------------------------------------------------------
# Initialize workspace on first start
# ---------------------------------------------------------------------------

if [[ ! -f "${STATE_DIR}/workspace/AGENTS.md" ]]; then
    echo "INFO: First start - running onboard to initialize workspace." >&2
    nanobot onboard --no-input 2>/dev/null || nanobot onboard < /dev/null 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Start WhatsApp bridge (if enabled)
# ---------------------------------------------------------------------------

BRIDGE_PID=""

cleanup() {
    if [[ -n "${BRIDGE_PID}" ]]; then
        kill "${BRIDGE_PID}" 2>/dev/null || true
        wait "${BRIDGE_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

if [[ "${WHATSAPP_ENABLED}" == "true" ]]; then
    BRIDGE_DIR=""

    # Find bridge directory in installed package
    BRIDGE_DIR="$(python3 -c "
import nanobot, os
pkg_dir = os.path.dirname(nanobot.__file__)
bridge = os.path.join(pkg_dir, '..', 'bridge')
if os.path.isdir(bridge):
    print(os.path.realpath(bridge))
" 2>/dev/null || true)"

    if [[ -z "${BRIDGE_DIR}" || ! -d "${BRIDGE_DIR}" ]]; then
        BRIDGE_DIR="$(find /usr/lib/python3* /usr/local/lib/python3* -path '*/bridge/package.json' -exec dirname {} \; 2>/dev/null | head -1)"
    fi

    # Copy to user dir if needed and build
    USER_BRIDGE_DIR="${STATE_DIR}/.nanobot/bridge"
    if [[ -n "${BRIDGE_DIR}" && -d "${BRIDGE_DIR}" ]]; then
        if [[ ! -f "${USER_BRIDGE_DIR}/dist/index.js" ]]; then
            mkdir -p "${USER_BRIDGE_DIR}"
            cp -a "${BRIDGE_DIR}/." "${USER_BRIDGE_DIR}/"
            cd "${USER_BRIDGE_DIR}"
            npm install && npm run build
            cd /
        fi
    fi

    if [[ -f "${USER_BRIDGE_DIR}/dist/index.js" ]]; then
        export BRIDGE_PORT=3001
        export AUTH_DIR="${STATE_DIR}/.nanobot/whatsapp-auth"
        mkdir -p "${AUTH_DIR}"
        node "${USER_BRIDGE_DIR}/dist/index.js" &
        BRIDGE_PID=$!
        echo "INFO: WhatsApp bridge started (PID ${BRIDGE_PID})." >&2
        sleep 2
    else
        echo "WARN: WhatsApp bridge not found - WhatsApp channel will not work." >&2
    fi
fi

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

echo "=========================================="
echo "Nanobot Add-on"
echo "Provider: ${PROVIDER}"
if [[ -n "${MODEL}" && "${MODEL}" != "null" ]]; then
    echo "Model: ${MODEL}"
fi
echo "Runtime mode: gateway"
echo "State dir: ${STATE_DIR}"
echo "Telegram: ${TELEGRAM_ENABLED}"
echo "Discord: ${DISCORD_ENABLED}"
echo "WhatsApp: ${WHATSAPP_ENABLED}"
echo "=========================================="

# ---------------------------------------------------------------------------
# Start nanobot gateway
# ---------------------------------------------------------------------------

exec nanobot gateway
