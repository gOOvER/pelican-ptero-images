FROM        node:18-alpine

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

RUN         apk update \
            && apk upgrade

RUN         apk add --no-cache \
                autoconf \
                automake \
                build-base \
                ca-certificates\
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
                python3 \
                python3-dev \
                sqlite \
                tzdata \
                zip \
                libc6-compat

# updating npm
RUN         npm install npm@next-10 -g
RUN         npm install -g typescript@latest ts-node@latest

## Setup user and working directory
RUN         adduser -D -h /home/container container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD	        ["/bin/ash", "/entrypoint.sh"]
