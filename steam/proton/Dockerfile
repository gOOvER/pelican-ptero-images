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
    alsa-tools \
    ca-certificates \
    cabextract \
    curl \
    dbus \
    ffmpeg \
    file \
    git \
    iproute2 \
    jq \
    locales \
    numactl \
    mesa-utils \
    net-tools \
    netcat-openbsd \
    openssl \
    pulseaudio \
    python3-full \
    python3-venv \
    steam-devices \
    tar \
    tini \
    wget \
    winbind \
    xvfb \
    lib32gcc-s1 \
    libao-common \
    libasound2 \
    libfreetype6 \
    libfreetype6:i386 \
    libsdl1.2debian \
    libsdl1.2debian:i386 \
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
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-pulseaudio \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Download and install Proton-GE latest release into /opt and register with Steam
RUN set -eux; cd /tmp; \
    # Fetch release JSON using curl (already installed in layer 1)
    PROTON_JSON=$(curl -sSf https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest 2>&1) || { echo "Failed to fetch Proton-GE releases" >&2; exit 1; }; \
    # Extract .tar.gz URL using jq (installed in layer 1)
    PROTON_URL=$(printf '%s' "$PROTON_JSON" | jq -r '.assets[].browser_download_url' 2>/dev/null | grep '\.tar\.gz$' | head -n1) || { echo "Failed to parse Proton-GE release JSON" >&2; exit 1; }; \
    [ -n "$PROTON_URL" ] || { echo "No Proton-GE .tar.gz found in latest release" >&2; exit 1; }; \
    # Extract checksum URL
    PROTON_CHECKSUM_URL=$(printf '%s' "$PROTON_JSON" | jq -r '.assets[].browser_download_url' 2>/dev/null | grep '\.sha512sum$' | head -n1) || true; \
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
