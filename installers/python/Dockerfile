FROM        --platform=$TARGETOS/$TARGETARCH python:3.14-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG 		DEBIAN_FRONTEND=noninteractive

RUN         apt update \
		        && apt -y upgrade

RUN         apt -y install --no-install-recommends \
                build-essential \
                ca-certificates \
                curl \
                default-libmysqlclient-dev \
                dnsutils \
                ffmpeg \
				file \
                g++ \
                gcc \
                git \
                iproute2 \
				jq \
				libtool \
                llvm \
                locales \
                make \
                openjdk-21-jre-headless \
				pipx \
                procps \
				python3-pip \
                tk-dev \
                uuid-dev \
				unzip \
                wget \
                xz-utils \
                zlib1g-dev \
                libbz2-dev \
                libffi-dev \
                libgdbm-dev \
                liblzma-dev \
                libncurses5-dev \
                libreadline-dev \
                libsqlite3-dev \
                libssl-dev \
                libxml2-dev \
                libxmlsec1-dev && \
            apt clean && \
            rm -rf /var/lib/apt/lists/*

RUN         python -m pip install --upgrade pip
RUN 	    pip install itch-dl

