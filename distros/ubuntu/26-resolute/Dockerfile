FROM            --platform=$TARGETOS/$TARGETARCH ubuntu:26.04

LABEL       	org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       	org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       	org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       	org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG             DEBIAN_FRONTEND noninteractive

## update base packages
RUN             apt update \
                && apt -y upgrade

## install dependencies
RUN             apt install -y \
                        nala \
                        apt-transport-https \
                        binutils \
                        bzip2 \
                        cabextract \
                        curl \
                        ffmpeg \
                        g++ \
                        gcc \
                        gdb \
                        git \
                        icu-devtools \
                        init-system-helpers \
                        iproute2 \
                        locales \
                        net-tools \
                        netcat-openbsd \
                        sqlite3 \
                        tar \
                        telnet \
                        unzip \
                        wget \
                        xz-utils \
                        zip \
                        zlib1g \
                        libatomic1 \
                        libc++-dev \
                        libc6 \
                        libcurl3-gnutls \
                        libfontconfig \
                        libgcc1 \
                        liblua5.1-0 \
                        libluajit-5.1-2 \
                        liblzo2-2 \
                        libmariadb-dev \
                        libsdl1.2debian \
                        libsdl2-2.0-0 \
                        libsqlite3-0 \
                        libsqlite3-dev \
                        libssl-dev \
                        libunwind8

## configure locale
RUN             sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
                && localedef -i en_US -f UTF-8 en_US.UTF-8 || true \
                && export LANG=en_US.UTF-8 \
                && dpkg-reconfigure --frontend noninteractive locales

## Setup user and working directory
RUN             useradd -m -d /home/container -s /bin/bash container
USER            container
ENV             USER=container HOME=/home/container
WORKDIR         /home/container

COPY            ./../entrypoint.sh /entrypoint.sh
CMD             ["/bin/bash", "/entrypoint.sh"]
