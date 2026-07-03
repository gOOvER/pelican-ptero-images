# ---------------------------------------------
# Steam Proton-GE image (with Protontricks)
# ---------------------------------------------
FROM ubuntu:26.04

LABEL org.opencontainers.image.description="STEAM Proton-GE Image for Pelican/Pterodactyl Gamepanel"
LABEL org.opencontainers.image.authors="info@goover.de"
LABEL org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

# -----------------------------
# System preparation
# -----------------------------
RUN dpkg --add-architecture i386 \
    && apt update && apt -y upgrade \
    && apt install -y --no-install-recommends \
        ca-certificates \
        cabextract \
        curl \
        dbus \
        file \
        jq \
        locales \
        numactl \
        openssl \
        python3 \
        tar \
        tini \
        wget \
        winbind \
        xvfb \
        lib32gcc-s1 \
        libasound2 \
        libfreetype6 \
        libfreetype6:i386 \
        libsdl2-2.0-0 \
        libsdl2-2.0-0:i386 \
        libssl3 \
        libssl3:i386 \
        libgdiplus \
        libncurses6 \
        libntlm0 \
        libnss-wrapper \
        libnss3 \
        libpulse-dev \
        libpulse0 \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
    && apt clean && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Set locale
# -----------------------------
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# -----------------------------
# Create container user
# -----------------------------
RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
ENV PATH="$HOME/.local/bin:$PATH"

# -----------------------------
# Proton-GE installation (global)
# -----------------------------
ARG GITHUB_TOKEN=""
USER root
RUN set -eux; cd /tmp; \
    curl_args=(-sSf); \
    [ -n "${GITHUB_TOKEN:-}" ] && curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}"); \
    PROTON_JSON=$(curl "${curl_args[@]}" https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest) || { echo "Failed to fetch Proton-GE releases" >&2; exit 1; }; \
    # Extract x86_64 .tar.gz URL - match only bare "GE-ProtonXX-Y.tar.gz" (no arch suffix)
    # GE-Proton11-1 introduced separate aarch64 builds; without this filter
    # head -n1 would grab the aarch64 tarball first (it appears earlier in the API response)
    # causing ENOEXEC at runtime when x86_64 tries to execute ARM64 wine binaries.
    PROTON_URL=$(printf '%s' "$PROTON_JSON" | jq -r '.assets[] | select(.name | test("^GE-Proton[0-9]+-[0-9]+\\.tar\\.gz$")) | .browser_download_url' 2>/dev/null | head -n1) || { echo "Failed to parse Proton-GE release JSON" >&2; exit 1; }; \
    [ -n "$PROTON_URL" ] || { echo "No Proton-GE x86_64 .tar.gz found in latest release" >&2; exit 1; }; \
    curl -sSL "$PROTON_URL" -o proton-ge.tar.gz || { echo "Failed to download Proton-GE from $PROTON_URL" >&2; exit 1; }; \
    mkdir -p /opt/ProtonGE /usr/local/bin && tar -xzf proton-ge.tar.gz -C /opt/ProtonGE --strip-components=1; \
    rm -rf proton-ge.tar.gz /tmp/*; \
    ln -sf /opt/ProtonGE/proton /usr/local/bin/proton-ge; \
    ln -sf /opt/ProtonGE/proton /usr/local/bin/proton; \
    ln -sf /home/container/.proton-dist.lock /opt/ProtonGE/dist.lock

# Python 3.13 posix_spawn ENOEXEC fix for files/bin/wine.
# posix_spawn does NOT fall back to /bin/sh for scripts without a shebang —
# it returns ENOEXEC immediately (unlike the old fork+exec path in Python ≤3.12).
# Use `file -b` for reliable ELF detection instead of od|grep, and log every
# branch so the build output shows exactly what was (or wasn't) patched.
RUN set -eu; \
    WINE_BIN=/opt/ProtonGE/files/bin/wine; \
    if [ ! -f "$WINE_BIN" ]; then \
        echo "WARN: $WINE_BIN not found — ProtonGE layout may have changed" >&2; \
        ls -la /opt/ProtonGE/files/bin/ >&2 || true; \
    elif file -b "$WINE_BIN" | grep -q '^ELF'; then \
        echo "files/bin/wine is an ELF binary — posix_spawn exec OK, no patch needed"; \
    elif [ "$(head -c2 "$WINE_BIN")" = '#!' ]; then \
        echo "files/bin/wine already has shebang: $(head -n1 "$WINE_BIN") — no patch needed"; \
    else \
        echo "files/bin/wine is a script without shebang — prepending #!/bin/sh (Python 3.13 ENOEXEC fix)"; \
        { printf '#!/bin/sh\n'; cat "$WINE_BIN"; } > "${WINE_BIN}.new" \
            && mv "${WINE_BIN}.new" "$WINE_BIN" \
            && chmod +x "$WINE_BIN"; \
        echo "Patched. First line is now: $(head -n1 "$WINE_BIN")"; \
    fi

# GE-Proton11 no longer bundles a pre-built default_pfx in the release tarball.
# On first run proton calls wine wineboot and writes to files/share/default_pfx/ —
# but that path is inside the read-only image layer in Pelican/Pterodactyl.
# Redirect to /home/container/.proton-default-pfx (writable persistent volume).
RUN if [ ! -d /opt/ProtonGE/files/share/default_pfx ] && [ ! -L /opt/ProtonGE/files/share/default_pfx ]; then \
        mkdir -p /opt/ProtonGE/files/share && \
        ln -sf /home/container/.proton-default-pfx \
            /opt/ProtonGE/files/share/default_pfx; \
    fi

# -----------------------------
# Winetricks installation (global)
# -----------------------------
RUN wget -q -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    && wget -q -O /usr/share/bash-completion/completions/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion

# -----------------------------
# RCON CLI installation (latest release)
# -----------------------------
RUN set -eux; cd /tmp; \
    RCON_LATEST=$(curl -sSf https://api.github.com/repos/gorcon/rcon-cli/releases/latest 2>&1 | jq -r '.assets[] | select(.name | contains("amd64_linux")) | .browser_download_url' | head -n1) || true; \
    if [ -n "$RCON_LATEST" ]; then \
        curl -sSL "$RCON_LATEST" -o rcon.tar.gz && tar -xzf rcon.tar.gz && \
        mv rcon-*-amd64_linux/rcon /usr/local/bin/ 2>/dev/null && chmod +x /usr/local/bin/rcon || true; \
    fi; \
    rm -rf /tmp/*

# -----------------------------
# Default stop signal and entrypoint
# -----------------------------
STOPSIGNAL SIGINT
# Copy entrypoint - build context must be steam/ (one level above this Dockerfile)
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
