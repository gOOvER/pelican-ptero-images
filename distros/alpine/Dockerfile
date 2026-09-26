ARG ALPINE_TAG=latest
ARG ALPINE_BRANCH=latest-stable
FROM        --platform=$BUILDPLATFORM alpine:${ALPINE_TAG}

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

RUN         apk add --update --no-cache \
				ca-certificates \
				tzdata \
				binutils \
                curl \
                g++ \
                gcc \
                gdb \
                git \
                gnupg \
                iproute2 \
                net-tools \
                netcat-openbsd \
                rapidjson-dev \
                sqlite \
            	tar \
                busybox-extras \
                unzip \
                wget \
            	xz \
                zip \
                libatomic \
                libc++-dev \
                libc6-compat \
                fontconfig \
                libgcc \
                icu \
                lua5.4 \
            	lzo \
                libprotobuf \
                sqlite \
				sqlite-dev \
                libssl3 \
                libstdc++ \
                libunwind \
            	zlib-dev

## Community Repo packages
RUN         apk add --update --no-cache \
				cabextract --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community \
				ffmpeg --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community \
				git-lfs --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community \
				duktape --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community \
				fluidsynth --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community \
				sdl2 --repository=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community

## Setup user and working directory
RUN         adduser -D -h /home/container container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/ash", "/entrypoint.sh" ]
