ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm

FROM ${BUILD_FROM}

ARG NANOBOT_VERSION=0.1.4

# Install Python, Node.js 20, and system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        python3 \
        python3-pip \
        python3-venv \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get purge -y gnupg \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -sf /root/.local/bin/uv /usr/local/bin/uv

# Remove PEP 668 marker so uv can install system-wide
RUN rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

# Install nanobot from PyPI
RUN uv pip install --system "nanobot-ai==${NANOBOT_VERSION}"

# Build WhatsApp bridge
RUN BRIDGE_DIR="$(python3 -c "import nanobot; import os; print(os.path.join(os.path.dirname(nanobot.__file__), '..', 'bridge'))")" \
    && if [ -d "${BRIDGE_DIR}" ]; then \
        cd "${BRIDGE_DIR}" && npm install && npm run build; \
    else \
        BRIDGE_DIR="$(find /usr/lib/python3* /usr/local/lib/python3* -path '*/bridge/package.json' -exec dirname {} \; 2>/dev/null | head -1)" \
        && if [ -n "${BRIDGE_DIR}" ]; then \
            cd "${BRIDGE_DIR}" && npm install && npm run build; \
        else \
            echo "WARN: WhatsApp bridge directory not found, skipping build" >&2; \
        fi; \
    fi

COPY run.sh /run.sh
RUN chmod a+x /run.sh

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Marco SeoFood" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Nanobot Home Assistant Add-ons" \
    org.opencontainers.image.authors="Marco" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/SeoFood/hassio-addons-nanobot" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

CMD ["/run.sh"]
