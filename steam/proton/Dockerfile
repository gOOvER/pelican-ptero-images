# ---------------------------------------------
# Steam Proton-GE image
# ---------------------------------------------
FROM debian:trixie-slim

# Metadata
LABEL org.opencontainers.image.description="STEAM Proton-GE Image to use with Pelican/Pterodactyl Gamepanel"
LABEL org.opencontainers.image.authors="info@goover.de"
LABEL org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

# Use bash as default shell
SHELL ["/bin/bash", "-c"]

# Set noninteractive frontend for apt
ARG DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture, update system, install packages in one layer
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    cabextract \
    curl \
    dbus \
    file \
    jq \
    locales \
    numactl \
    openssl \
    python3-full \
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
    mesa-vulkan-drivers:i386 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Download and install Proton-GE latest release into /opt and register with Steam
ARG GITHUB_TOKEN=""
RUN set -eux; cd /tmp; \
    # Fetch release JSON - use GITHUB_TOKEN if available to avoid API rate limiting (403)
    curl_args=(-sSf); \
    [ -n "${GITHUB_TOKEN:-}" ] && curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}"); \
    PROTON_JSON=$(curl "${curl_args[@]}" https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest 2>&1) || { echo "Failed to fetch Proton-GE releases" >&2; exit 1; }; \
    # Extract x86_64 .tar.gz URL - match only bare "GE-ProtonXX-Y.tar.gz" (no arch suffix)
    # GE-Proton11-1 introduced separate aarch64 builds; without this filter
    # head -n1 would grab the aarch64 tarball first (it appears earlier in the API response)
    # causing ENOEXEC at runtime when x86_64 tries to execute ARM64 wine binaries.
    PROTON_URL=$(printf '%s' "$PROTON_JSON" | jq -r '.assets[] | select(.name | test("^GE-Proton[0-9]+-[0-9]+\\.tar\\.gz$")) | .browser_download_url' 2>/dev/null | head -n1) || { echo "Failed to parse Proton-GE release JSON" >&2; exit 1; }; \
    [ -n "$PROTON_URL" ] || { echo "No Proton-GE x86_64 .tar.gz found in latest release" >&2; exit 1; }; \
    # Extract matching checksum URL (same name pattern without arch suffix)
    PROTON_CHECKSUM_URL=$(printf '%s' "$PROTON_JSON" | jq -r '.assets[] | select(.name | test("^GE-Proton[0-9]+-[0-9]+\\.sha512sum$")) | .browser_download_url' 2>/dev/null | head -n1) || true; \
    # Download Proton-GE tarball
    curl -sSL "$PROTON_URL" -o proton-ge.tar.gz || { echo "Failed to download Proton-GE from $PROTON_URL" >&2; exit 1; }; \
    [ -s proton-ge.tar.gz ] || { echo "Downloaded Proton-GE archive is empty" >&2; exit 1; }; \
    # Validate checksum if available
    if [ -n "$PROTON_CHECKSUM_URL" ]; then \
        curl -sSL "$PROTON_CHECKSUM_URL" -o proton-ge.sha512sum && \
        EXPECTED_HASH=$(awk '{print $1}' proton-ge.sha512sum | head -n1) && \
        [ -n "$EXPECTED_HASH" ] || { echo "Failed to extract hash from checksum file" >&2; exit 1; }; \
        ACTUAL_HASH=$(sha512sum proton-ge.tar.gz | awk '{print $1}') && \
        [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ] || { echo "Proton-GE checksum validation failed: expected $EXPECTED_HASH but got $ACTUAL_HASH" >&2; exit 1; }; \
    fi; \
    # Extract and normalize directory name
    mkdir -p /opt && tar -xzf proton-ge.tar.gz -C /opt; \
    PROTON_DIR=$(find /opt -maxdepth 1 -type d -name 'GE-Proton*' -print -quit); \
    [ -n "$PROTON_DIR" ] && mv "$PROTON_DIR" /opt/ProtonGE || { echo "Failed to find extracted Proton-GE directory" >&2; exit 1; }; \
    # Register tool for Steam - symlink avoids duplicating several GB
    mkdir -p /usr/local/share/steam/compatibilitytools.d; \
    rm -rf /usr/local/share/steam/compatibilitytools.d/ProtonGE 2>/dev/null || true; \
    ln -s /opt/ProtonGE /usr/local/share/steam/compatibilitytools.d/ProtonGE; \
    rm -rf /tmp/*

# Proton machine-id fix
RUN rm -f /etc/machine-id /var/lib/dbus/machine-id && \
    dbus-uuidgen --ensure=/etc/machine-id && \
    dbus-uuidgen --ensure

# Install Winetricks and bash completion
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/sbin/winetricks && \
    wget -q -O /usr/share/bash-completion/completions/winetricks \
    https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion && \
    rm -rf /tmp/*

# ALSA null device - headless servers have no sound hardware.
# Without this, libasound2 logs a flood of "cannot find card '0'" errors
# whenever Wine/Proton attempts to open the default PCM device.
RUN printf 'pcm.!default {\n    type null\n}\nctl.!default {\n    type null\n}\n' > /etc/asound.conf

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Virtual display for headless Proton/Wine (xalia, SDL-based apps)
ENV DISPLAY=:99
ENV DISPLAY_WIDTH=1024
ENV DISPLAY_HEIGHT=768
ENV DISPLAY_DEPTH=24

# RCON CLI installation (latest release) - uses jq for reliable parsing
RUN set -eux; cd /tmp; \
    RCON_LATEST=$(curl -sSf https://api.github.com/repos/gorcon/rcon-cli/releases/latest 2>&1 | jq -r '.assets[] | select(.name | contains("amd64_linux")) | .browser_download_url' | head -n1) || true; \
    if [ -n "$RCON_LATEST" ]; then \
        curl -sSL "$RCON_LATEST" -o rcon.tar.gz && tar -xzf rcon.tar.gz && \
        mv rcon-*-amd64_linux/rcon /usr/local/bin/ 2>/dev/null && chmod +x /usr/local/bin/rcon || true; \
    fi; \
    rm -rf /tmp/*

# Provide a simple system-wide `proton` wrapper that launches the installed
# Proton-GE. Create this as root (before switching to non-root user) so the
# wrapper is owned by root and executable by all users.
RUN set -eux; \
    printf '%s\n' '#!/bin/bash' \
        'set -euo pipefail' \
        'if [ -d /opt/ProtonGE ]; then' \
        '    PROTON_DIR=/opt/ProtonGE' \
        'elif [ -d /usr/local/share/steam/compatibilitytools.d/ProtonGE ]; then' \
        '    PROTON_DIR=/usr/local/share/steam/compatibilitytools.d/ProtonGE' \
        'else' \
        '    echo "Proton-GE not found (expected in /opt/ProtonGE or /usr/local/share/steam/compatibilitytools.d/ProtonGE)" >&2' \
        '    exit 1' \
        'fi' \
        '' \
        '# Common candidate locations for Proton launcher' \
        'CANDIDATES=("$PROTON_DIR/proton" "$PROTON_DIR/proton.sh" "$PROTON_DIR/bin/proton" "$PROTON_DIR/dist/bin/proton" "$PROTON_DIR/x86_64/bin/proton")' \
        'for p in "${CANDIDATES[@]}"; do' \
        '    if [ -x "$p" ]; then' \
        '        exec "$p" "$@"' \
        '    fi' \
        'done' \
        '' \
        '# Fallback: search for an executable named proton* within the Proton dir' \
        'FOUND=$(find "$PROTON_DIR" -maxdepth 4 -type f -iname "proton*" -executable -print -quit 2>/dev/null || true)' \
        'if [ -n "${FOUND:-}" ]; then' \
        '    exec "${FOUND}" "$@"' \
        'fi' \
        '' \
        '# If we reach here, no executable was found. Report helpful diagnostics.' \
        'echo "Proton executable not found or not executable inside $PROTON_DIR" >&2' \
        'echo "Contents (top-level):" >&2; ls -la "$PROTON_DIR" >&2 || true' \
        'exit 1' \
    > /usr/local/bin/proton; \
    chmod 755 /usr/local/bin/proton

# Pre-create X11 socket directory as root with sticky bit so Xvfb can run as non-root
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Redirect dist.lock to /home/container which is the only writable path in Pelican/Pterodactyl
# (root filesystem is read-only; /tmp is not mounted; only /home/container is writable).
RUN ln -sf /home/container/.proton-dist.lock /opt/ProtonGE/dist.lock

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

# Create non-root user and set working directory
RUN useradd -m -d /home/container -s /bin/bash container && mkdir -p /home/container && chown container:container /home/container
ENV USER=container HOME=/home/container
WORKDIR /home/container
USER container

# Default stop signal
STOPSIGNAL SIGINT

# Copy entrypoint - build context must be steam/ (one level above this Dockerfile)
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use tini init and entrypoint script
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
