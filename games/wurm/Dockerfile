FROM        debian:bullseye-slim

LABEL      org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG         DEBIAN_FRONTEND=noninteractive

RUN         dpkg --add-architecture i386
RUN         apt update
RUN         apt upgrade -y
RUN         apt install -y \
                apt-transport-https \
                curl \
                g++ \
                gcc \
                gdb \
                git \
                iproute2 \
                jq \
                mesa-utils \
                net-tools \
                netcat-openbsd \
                psmisc \
                python3 \
                python3-dev \
                python3-pip \
                sed \
                sqlite3 \
                tar \
                telnet \
                tzdata \
                wget \
                xvfb \
                lib32gcc-s1 \
                lib32stdc++6 \
                lib32tinfo6 \
                lib32z1 \
                libasound2 \
                libatk1.0-0 \
                libc6:i386 \
                libcurl3-gnutls:i386 \
                libcurl4 \
                libcurl4 \
                libcurl4-gnutls-dev:i386 \
                libcurl4:i386 \
                libfontconfig1 \
                libfontconfig1 \
                libgcc1 \
                libgconf-2-4 \
                libgdiplus \
                libncurses5:i386 \
                libnss3 \
                libpangocairo-1.0-0 \
                libpulse-dev \
                libsdl1.2debian \
                libsdl2-2.0-0 \
                libsdl2-2.0-0:i386 \
                libstdc++6 \
                libstdc++6:i386 \
                libswt-gtk-4-java \
                libtcmalloc-minimal4 \
                libtinfo6:i386 \
                libxcomposite1 \
                libxcursor1 \
                libxdamage1 \
                libxi6 \
                libxrandr2 \
                libxss1 \
                libxtst6

RUN         mkdir -p /etc/apt/keyrings
RUN         wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
RUN         echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN         apt update
RUN         apt install temurin-8-jdk -y

ENV         DISPLAY=:0
ENV         DISPLAY_WIDTH=1024
ENV         DISPLAY_HEIGHT=768
ENV         DISPLAY_DEPTH=16

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]
