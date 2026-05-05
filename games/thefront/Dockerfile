FROM        debian:bookworm-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG         DEBIAN_FRONTEND=noninteractive

RUN         dpkg --add-architecture i386
RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
                    nala \
                    ca-certificates \
                    curl \
                    dbus \
                    dirmngr \
                    g++ \
                    gcc \
                    gdb \
                    git \
                    gnupg \
                    iproute2 \
                    jq \
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
                    lib32z1 \
                    libasound2 \
                    libatk1.0-0 \
                    libc++1 \
                    libc6:i386 \
                    libcurl4 \
                    libcurl4:i386 \
                    libcurl4-gnutls-dev:i386 \
                    libfontconfig1 \
                    libgcc1 \
                    libgconf-2-4 \
                    libgdiplus \
                    libgtk2.0-0:i386 \
                    libncurses5:i386 \
                    libnss-wrapper \
                    libnss-wrapper:i386 \
                    libnss3 \
                    libpangocairo-1.0-0 \
                    libpulse-dev \
                    libsdl1.2debian \
                    libsdl1.2debian:i386 \
                    libsdl2-2.0-0 \
                    libsdl2-2.0-0:i386 \
                    libssl3 \
                    libssl3:i386 \
                    libstdc++6 \
                    libstdc++6:i386 \
                    libtcmalloc-minimal4 \
                    libtinfo6:i386 \
                    libxcomposite1 \
                    libxcursor1 \
                    libxdamage1 \
                    libxi6 \
                    libxrandr2 \
                    libxss1 \
                    libxtst6 \
			&& apt-get clean \
			&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## install rcon
RUN         cd /tmp/ \
            && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
            && tar xvf rcon.tar.gz \
            && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/

## Prepare NSS Wrapper for the entrypoint as a workaround for Arma 3 requiring a valid UID
RUN         touch /tmp/passwd /tmp/group \
            && chgrp 0 /tmp/passwd /tmp/group \
            && chmod g+rw /tmp/passwd /tmp/group
ADD         passwd.template /passwd.template

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# Sets the default stop signal as wings can (currently) only send a kill or generic stop
STOPSIGNAL SIGINT

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
