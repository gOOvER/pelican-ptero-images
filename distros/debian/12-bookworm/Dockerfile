FROM            --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL	       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL   	   org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL          org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL          org.opencontainers.image.licenses=AGPL-3.0-or-later

ARG             DEBIAN_FRONTEND=noninteractive

## update base packages
RUN             apt update \
                && apt -y upgrade

## Install dependencies
RUN         apt install -y \
                nala \
                binutils \
                ca-certificates \
                cabextract \
                curl \
                ffmpeg \
                file \
                g++ \
                gcc \
                gdb \
                git \
                git-lfs \
                gnupg2 \
                icu-devtools \
                iproute2 \
                jq \
				locales \
                net-tools \
                netcat-openbsd \
                rapidjson-dev \
                software-properties-common \
                sqlite3 \
                tar \
                telnet \
                tzdata \
                unzip \
                wget \
                xz-utils \
                zip \
                zstd \
                libatomic1 \
                libc++-dev \
                libc6 \
                libduktape207 \
                libfluidsynth3 \
                libfontconfig \
                libgcc1 \
                libicu72 \
                liblua5.4-0 \
                liblzo2-2 \
                libmariadbclient-dev-compat \
                libprotobuf32 \
                libsdl1.2debian \
                libsdl2-2.0-0 \
                libsqlite3-dev \
                libssl-dev \
                libstdc++6 \
                libunwind8 \
                libz-dev

## configure locale
RUN     	sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 		&& localedef -i en_US -f UTF-8 en_US.UTF-8 || true \
 		&& export LANG=en_US.UTF-8 \
         		&& dpkg-reconfigure --frontend noninteractive locales

## Setup user and working directory
RUN     	useradd -m -d /home/container -s /bin/bash container
USER    	container
ENV     	USER=container HOME=/home/container
WORKDIR 	/home/container

COPY    	./../entrypoint.sh /entrypoint.sh
CMD     	["/bin/bash", "/entrypoint.sh"]
