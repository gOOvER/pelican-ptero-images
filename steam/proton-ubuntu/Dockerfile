# ---------------------------------------------
# Steam Proton-GE image (with Protontricks)
# ---------------------------------------------
FROM ubuntu:24.04

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
        nala \
        ca-certificates \
        curl \
        file \
        git \
        gnupg \
        gnupg2 \
        gnutls-bin \
        iproute2 \
        locales \
        net-tools \
        netcat-openbsd \
        openssl \
        pulseaudio \
        wget \
        xauth \
        xvfb \
        tar \
        tini \
        virt-what \
        yad \
        alsa-tools \
        ffmpeg \
        mesa-utils \
        libao-common \
        libpulse-dev \
        libpulse0 \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-venv \
        pipx \
        cabextract \
        winbind \
        libsdl1.2debian \
        libsdl1.2debian:i386 \
        libsdl2-2.0-0 \
        libsdl2-2.0-0:i386 \
        libfreetype6 \
        libfreetype6:i386 \
        lib32gcc-s1 \
        libgdiplus \
        libncurses5-dev:i386 \
        libncurses6 \
        libssl3 \
        libssl3:i386 \
        libntlm0 \
        libnss-wrapper \
        libnss3 \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        gstreamer1.0-x \
        gstreamer1.0-alsa \
        gstreamer1.0-gl \
        gstreamer1.0-pulseaudio \
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
USER root
RUN mkdir -p /opt/ProtonGE /usr/local/bin && cd /tmp \
    && PROTON_URL=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
        | grep browser_download_url | cut -d\" -f4 | grep '\.tar\.gz$') \
    && curl -sLOJ "$PROTON_URL" \
    && tar -xzf GE-Proton*.tar.gz -C /opt/ProtonGE --strip-components=1 \
    && rm GE-Proton*.* \
    && ln -sf /opt/ProtonGE/proton /usr/local/bin/proton-ge \
    && ln -sf /opt/ProtonGE/proton /usr/local/bin/proton \
    && touch /opt/ProtonGE/dist.lock && chmod 666 /opt/ProtonGE/dist.lock

# -----------------------------
# Winetricks installation (global)
# -----------------------------
RUN wget -q -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    && wget -q -O /usr/share/bash-completion/completions/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion

# -----------------------------
# Pipx PATH setup (pipx installed via apt above)
# -----------------------------
RUN python3 -m pipx ensurepath || true

# -----------------------------
# RCON CLI installation (latest, dynamisch)
# -----------------------------
RUN cd /tmp \
    && RCON_URL=$(curl -s https://api.github.com/repos/gorcon/rcon-cli/releases/latest \
        | grep browser_download_url | cut -d\" -f4 | grep 'amd64_linux\.tar\.gz') \
    && curl -sLOJ "$RCON_URL" \
    && tar xvf rcon-*-amd64_linux.tar.gz \
    && mv rcon-*/rcon /usr/local/bin/ \
    && rm -rf /tmp/*

# -----------------------------
# Default stop signal and entrypoint
# -----------------------------
STOPSIGNAL SIGINT
# Copy entrypoint - build context must be steam/ (one level above this Dockerfile)
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
