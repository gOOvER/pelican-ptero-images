FROM        debian:trixie-slim

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

# Update the repository and install needed packages
ARG         DEBIAN_FRONTEND=noninteractive
RUN         bash -lc 'set -euo pipefail; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends' \
            nala \
            ca-certificates \
            curl \
            dbus \
            dirmngr \
            g++ \
            gcc \
            gcc-12-base \
            gdb \
            gettext \
            git \
            gnupg \
            iproute2 \
            jq \
            locales \
            mesa-utils \
            net-tools \
            netcat-openbsd \
            numactl \
            psmisc \
            python3 \
            python3-dev \
            python3-pip \
            sed \
            speex:i386 \
            tar \
            telnet \
            tini \
            tzdata \
            wget \
            lib32gcc-s1 \
            lib32stdc++6 \
            lib32tinfo6 \
            libtinfo6:i386 \
            lib32z1 \
            libasound2 \
            libatk1.0-0 \
            libatomic1 \
            libc++-dev \
            libc++1 \
            libc6 \
            libc6:i386 \
            libcurl3-gnutls \
            libcurl3-gnutls:i386 \
            libcurl4 \
            libcurl4-gnutls-dev \
            libcurl4-gnutls-dev:i386 \
            libcurl4:i386 \
            libfontconfig \
            libgcc-s1 \
            libgcc1 \
            libgdiplus \
            libgtk2.0-0:i386 \
            libjemalloc2 \
            libjemalloc2:i386 \
            libnss-wrapper \
            libnss3 \
            libpangocairo-1.0-0 \
            libpulse-dev \
            libpulse0 \
            libsdl1.2-compat \
            libsdl1.2-compat:i386 \
            libsdl1.2debian \
            libsdl1.2debian:i386 \
            libsdl2-2.0-0 \
            libsdl2-2.0-0:i386 \
            libssl3 \
            libssl3:i386 \
            libstdc++6 \
            libstdc++6:i386 \
            libtcmalloc-minimal4 \
            libtcmalloc-minimal4:i386 \
            libtinfo6:i386 \
            libxcomposite1 \
            libxcursor1 \
            libxdamage1 \
            libxi6 \
            libxrandr2 \
            libxss1 \
            libxtst6 \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

## install dotnet to support STEAM dotnet games
RUN         curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
            chmod +x /tmp/dotnet-install.sh && \
            /tmp/dotnet-install.sh -i /usr/share && \
            ln -s /usr/share/dotnet /usr/bin/dotnet && \
            rm -f /tmp/dotnet-install.sh'

## install rcon (download latest release from GitHub)
RUN         cd /tmp/; \
            TAG=$(curl -sSL https://api.github.com/repos/gorcon/rcon-cli/releases/latest | jq -r ".tag_name // empty"); \
            if [ -z "$TAG" ]; then echo "Failed to get rcon latest tag" >&2; exit 1; fi; \
            V=${TAG#v}; \
            URL="https://github.com/gorcon/rcon-cli/releases/download/${TAG}/rcon-${V}-amd64_linux.tar.gz"; \
            echo "Downloading rcon from ${URL}"; \
            curl --fail -L "$URL" -o rcon.tar.gz; \
            tar xzf rcon.tar.gz; \
            mv rcon-${V}-amd64_linux/rcon /usr/local/bin/; \
            chmod +x /usr/local/bin/rcon; \
            rm -rf /tmp/*'

## install mono official repo and packages
RUN apt-get update && apt-get install -y --no-install-recommends dirmngr ca-certificates gnupg; \
    nala \
    mkdir -p /usr/share/keyrings; \
    gpg --homedir /tmp --no-default-keyring --keyring /tmp/mono-temp-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF; \
    gpg --homedir /tmp --no-default-keyring --keyring /tmp/mono-temp-keyring.gpg --export --output /usr/share/keyrings/mono-official-archive-keyring.gpg; \
    chmod +r /usr/share/keyrings/mono-official-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-buster main" > /etc/apt/sources.list.d/mono-official-stable.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends mono-complete; \
    nala \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/*'

# Set the locale
RUN        	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
           	locale-gen

ENV      	LANG=en_US.UTF-8 \
	       	LANGUAGE=en_US:en \
        	LC_ALL=en_US.UTF-8

# Create non-root user and set working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# Default stop signal
STOPSIGNAL SIGINT

# Copy entrypoint (adjust path if needed)
ARG         ENTRYPOINT_PATH=../entrypoint.sh
COPY        --chown=container:container ${ENTRYPOINT_PATH} /entrypoint.sh
RUN         chmod +x /entrypoint.sh

# Use tini init and entrypoint script
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
