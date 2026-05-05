FROM    	debian:bullseye-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

ENV    		DEBIAN_FRONTEND noninteractive

## update base packages
RUN     	apt update \
        	&& apt -y upgrade

## Install dependencies
RUN     	apt install -y \
            	nala \
            	apt-transport-https \
            	binutils \
            	ca-certificates \
            	cabextract \
            	curl \
            	ffmpeg \
            	g++ \
            	gcc \
            	gdb \
            	git \
            	git-lfs \
            	gnupg2 \
            	icu-devtools \
            	iproute2 \
				locales \
            	net-tools \
            	netcat-openbsd \
            	rapidjson-dev \
            	software-properties-common \
            	sqlite3 \
            	tar \
            	telnet libatomic1 \
            	tzdata \
            	unzip \
            	wget \
            	xz-utils \
            	zip \
            	libc++-dev \
            	libc6 \
            	libduktape205 \
            	libfluidsynth2 \
            	libfontconfig \
            	libgcc1 \
            	libicu67 \
            	liblua5.4-0 \
            	liblzo2-2 \
            	libmariadbclient-dev-compat \
            	libprotobuf23 \
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
