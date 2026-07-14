FROM        --platform=$TARGETOS/$TARGETARCH node:18-bookworm-slim

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

ARG         DEBIAN_FRONTEND=noninteractive
RUN         apt update \
             && apt -y upgrade

RUN         apt -y install --no-install-recommends \
                autoconf \
                automake \
                build-essential \
                ca-certificates\
                curl \
                dnsutils \
				ffmpeg \
                g++ \
                git \
                gnupg \
                gnupg2 \
                iproute2 \
                iputils-ping \
                libtool \
                locales \
                python3 \
                python3-dev \
                sqlite3 \
                tzdata \
                tini \
                zip \
				libnss3 \
                libsqlite3-dev

# add Yarn
RUN         curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
            && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
            && apt update \
            && apt -y install yarn

# updating npm
RUN         npm install npm@next-10 -g
RUN         npm install typescript ts-node tsx @types/node --location=global

# install pnpm
RUN         npm install -g corepack
RUN         corepack enable
RUN         corepack prepare pnpm@latest --activate

# Set the locale
RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            locale-gen
ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8

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
