FROM        --platform=$TARGETOS/$TARGETARCH rust:slim

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"
RUN         apt update \
            && apt -y upgrade

RUN         apt -y install \
                autoconf \
                automake \
                build-essential \
                ca-certificates\
                curl \
                dnsutils \
                ffmpeg \
                g++ \
                git  \
                gnupg \
                gnupg2 \
                iproute2 \
                iputils-ping \
                libtool \
                locales \
                sqlite3 \
                tar \
                tini \
                tzdata \
                unzip \
                zip \
                zstd \
                libcairo2-dev \
                libgif-dev \
                libjpeg-dev \
                libnss3 \
                libpango1.0-dev \
                librsvg2-dev \
                libsqlite3-dev

# Set the locale
RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            locale-gen
ENV         LANG en_US.UTF-8
ENV         LANGUAGE en_US:en
ENV         LC_ALL en_US.UTF-8

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container CARGO_HOME=/home/container/.cargo
WORKDIR     /home/container

# Sets the default stop signal as wings can (currently) only send a kill or generic stop
STOPSIGNAL SIGINT

COPY        --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
