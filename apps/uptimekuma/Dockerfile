FROM        node:22-alpine

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

RUN         apk update \
            && apk upgrade

RUN         apk add --no-cache \
                autoconf \
                automake \
                build-base \
                ca-certificates\
                chromium \
                curl \
                bind-tools \
				ffmpeg \
                g++ \
                git \
                gpg \
                gnupg \
                iproute2 \
                iputils-ping \
                libtool \
                musl \
                musl-utils \
                musl-locales \
                py3-pip \
                python3 \
                python3-dev \
                pipx \
                sqlite \
                tzdata \
                zip \
                libc6-compat

RUN         apk add --update --no-cache \
				git-lfs --repository=https://dl-cdn.alpinelinux.org/alpine/latest-stable/community

# updating npm
RUN         npm install npm@latest -g

# download cloudflared
ARG         TARGETPLATFORM
RUN         if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
            && curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCHITECTURE} -o /usr/bin/cloudflared
RUN         chmod +x /usr/bin/cloudflared

# install apprise
RUN         pipx install apprise

# Set the locale
#RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
#            locale-gen
#ENV         LANG en_US.UTF-8
#ENV         LANGUAGE en_US:en
#ENV         LC_ALL en_US.UTF-8

## Setup user and working directory
RUN         adduser -D -h /home/container container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         ["/bin/ash", "/entrypoint.sh"]
