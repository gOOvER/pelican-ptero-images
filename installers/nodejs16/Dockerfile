FROM        --platform=$TARGETOS/$TARGETARCH node:16-bullseye-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG         DEBIAN_FRONTEND=noninteractive

RUN         apt update \
             && apt -y upgrade

RUN         apt -y install \
                nala \
                autoconf \
                automake \
                build-essential \
                ca-certificates\
                curl \
                dnsutils \
				ffmpeg \
                file \
                g++ \
                gcc \
                git \
                git-lfs \
                gpg \
                gnupg2 \
                iproute2 \
                iputils-ping \
                jq \
                libtool \
                make \
                python3 \
                python3-dev \
                sqlite3 \
                tzdata \
                zip \
                unzip \
				libnss3 \
                libsqlite3-dev

# updating npm
RUN         npm install npm@latest -g
