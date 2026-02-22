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

PERSISTENT_DATA_DIR="$(read_opt '.persistent_data_dir' 'nanobot')"

# ---------------------------------------------------------------------------
# Resolve state directory + migration
# ---------------------------------------------------------------------------

if [[ "${PERSISTENT_DATA_DIR}" == "null" ]]; then
    PERSISTENT_DATA_DIR="nanobot"
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
# Inject gateway defaults into config.json
# ---------------------------------------------------------------------------

CONFIG_FILE="${STATE_DIR}/.nanobot/config.json"

GATEWAY_DEFAULTS='{"gateway":{"host":"0.0.0.0","port":18790}}'

if [[ -f "${CONFIG_FILE}" ]]; then
    # Merge: user config takes precedence, gateway defaults fill in missing keys
    MERGED="$(jq -s '.[0] * .[1]' <(echo "${GATEWAY_DEFAULTS}") "${CONFIG_FILE}")"
    echo "${MERGED}" > "${CONFIG_FILE}"
else
    echo "${GATEWAY_DEFAULTS}" > "${CONFIG_FILE}"
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
# Start WhatsApp bridge (if enabled in config.json)
# ---------------------------------------------------------------------------

BRIDGE_PID=""

cleanup() {
    if [[ -n "${BRIDGE_PID}" ]]; then
        kill "${BRIDGE_PID}" 2>/dev/null || true
        wait "${BRIDGE_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

WHATSAPP_ENABLED="$(jq -r '.channels.whatsapp.enabled // false' "${CONFIG_FILE}" 2>/dev/null || echo 'false')"

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
echo "State dir: ${STATE_DIR}"
echo "Config: ${CONFIG_FILE}"
echo "Runtime mode: gateway"
echo "=========================================="

# ---------------------------------------------------------------------------
# Start nanobot gateway
# ---------------------------------------------------------------------------

exec nanobot gateway
