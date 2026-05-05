FROM  --platform=$TARGETOS/$TARGETARCH ubuntu:22.04

LABEL      org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

# Update the repository and install needed packages
ARG         DEBIAN_FRONTEND=noninteractive
RUN         dpkg --add-architecture i386
RUN         apt update \
            && apt -y upgrade

## install dependencies
RUN   apt install -y iproute2 \
        nala \
        curl \
        git \
        zip \
        unzip \
        tar \
		tini \
        xz-utils \
        apt-transport-https \
        openssl \
        libssl3 \
        default-libmysqlclient-dev \
        libmysqlclient-dev \
        libreadline-dev \
        libncurses-dev \
        libtool \
        python3  \
        locales \
        ffmpeg \
        libc6 \
        binutils  \
        liblua5.1-0

# Set the locale
RUN        	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
           	locale-gen
ENV      	LANG=en_US.UTF-8
ENV       	LANGUAGE=en_US:en
ENV        	LC_ALL=en_US.UTF-8

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# Sets the default stop signal as wings can (currently) only send a kill or generic stop
STOPSIGNAL SIGINT

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
