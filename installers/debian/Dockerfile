FROM        debian:trixie-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

## update base packages
ARG         DEBIAN_FRONTEND noninteractive
RUN        	dpkg --add-architecture i386
RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
				nala \
				build-essential \
				ca-certificates \
				curl \
				file \
				git \
				git-lfs \
				jq \
				locales \
				p7zip-full \
				python3 \
               	python3-dev \
               	python3-pip \
				tar \
				unzip \
				wget \
				zstd \
				lib32gcc-s1 \
				libcurl4 \
				libcurl4-gnutls-dev \
				libsdl2-2.0-0 \
			&& apt-get clean \
			&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## generate locale so setlocale('en_US.UTF-8') works
RUN    		sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
			locale-gen en_US.UTF-8 && \
			sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
			&& localedef -i en_US -f UTF-8 en_US.UTF-8 || true \
			&& export LANG=en_US.UTF-8

ENV 		LANG=en_US.UTF-8 \
    		LANGUAGE=en_US:en \
    		LC_ALL=en_US.UTF-8

## download lastest 7zip for archives
RUN 		wget https://www.7-zip.org/a/7z2501-linux-x64.tar.xz \
				&& tar xf 7z2501-linux-x64.tar.xz \
				&& mv 7zz /usr/local/bin \
				&& rm -f 7z2501-linux-x64.tar.xz
