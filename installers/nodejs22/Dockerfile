FROM        --platform=$TARGETOS/$TARGETARCH node:22-trixie-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG         DEBIAN_FRONTEND=noninteractive

RUN         apt update \
             && apt -y upgrade

RUN         apt -y install --no-install-recommends \
                nala \
                autoconf \
                automake \
                build-essential \
                ca-certificates\
				chromium \
                curl \
                dnsutils \
				ffmpeg \
                file \
				fonts-liberation \
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
				lsb-release \
				wget \
				xdg-utils \
				libatk1.0-0 \
				libatk-bridge2.0-0 \
				libnss3 \
                libsqlite3-dev \
				libasound2 \
				libc6 \
				libcairo2 \
				libcups2 \
				libdbus-1-3 \
				libexpat1 \
				libfontconfig1 \
				libgbm1 \
				libgcc1 \
				libglib2.0-0 \
				libgtk-3-0 \
				libnspr4 \
				libnss3 \
				libpango-1.0-0 \
				libpangocairo-1.0-0 \
				libstdc++6 \
				libx11-6 \
				libx11-xcb1 \
				libxcb1 \
				libxcomposite1 \
				libxcursor1 \
				libxdamage1 \
				libxext6 \
				libxfixes3 \
				libxi6 \
				libxrandr2 \
				libxrender1 \
				libxss1 \
				libxtst6

RUN         rm -rf /var/lib/apt/lists/*

RUN         npm install tsc typescript ts-node @types/node --location=global
RUN 	    yarn global add itchio-downloader
