FROM    	debian:bookworm-slim

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

## install required packages
ARG         DEBIAN_FRONTEND=noninteractive

RUN     	dpkg --add-architecture i386
RUN     	apt update
RUN     	apt -y upgrade
RUN     	apt install -y \
            	nala \
            	gnupg2 \
				locales \
            	software-properties-common \
            	libntlm0 \
            	winbind \
            	xvfb \
            	xauth \
            	python3 \
            	libncurses5:i386 \
            	libncurses6:i386 \
            	dbus \
            	wget \
            	curl

# Install wine and with recommends
RUN     	mkdir -pm755 /etc/apt/keyrings
RUN     	wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN     	wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
RUN     	apt update
RUN     	apt install -y  --install-recommends winehq-staging cabextract

# Set up Winetricks
RUN	    	wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
RUN     	chmod +x /usr/sbin/winetricks

#Static wine variables
ENV     	HOME=/home/container
ENV     	WINEPREFIX=/home/container/.wine
ENV     	WINE_ARCH=win64
ENV     	WINE_PREFIX_GAME_DIR=/home/container/Build
ENV     	WINE_PREFIX_GAME_CONFIG=/home/container/Build/config
ENV     	WINE_PREFIX_GAME_EXE=/home/container/Build/IR.exe
ENV     	WINEDLLOVERRIDES="mscoree,mshtml="
ENV     	WINDEBUG=-all
ENV     	DISPLAY=:0
ENV     	DISPLAY_WIDTH=1024
ENV     	DISPLAY_HEIGHT=768
ENV     	DISPLAY_DEPTH=16

# Set the locale
RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            locale-gen
ENV        	LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8

RUN         bash -c 'echo "vm.max_map_count = 16777216" > /etc/sysctl.d/20-max_map_count.conf'

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
