FROM        alpine:latest

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

# Install wine and wget
RUN         apk update
RUN         apk upgrade
RUN         apk add --no-cache tzdata xvfb wget curl git
RUN         apk add wine --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community --allow-untrusted
RUN         apk add winetricks --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community --allow-untrusted || \
            (wget -q -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && chmod +x /usr/local/bin/winetricks)

# ENV
ENV         HOME=/home/container
ENV         WINEPREFIX=/home/container/.wine
ENV         WINEDLLOVERRIDES="mscoree,mshtml="
ENV         DISPLAY=:0
ENV         DISPLAY_WIDTH=1024
ENV         DISPLAY_HEIGHT=768
ENV         DISPLAY_DEPTH=16

## Setup user and working directory
RUN         adduser -D -h /home/container container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

#
COPY        ./entrypoint.sh /entrypoint.sh
CMD	        ["/bin/ash", "/entrypoint.sh"]
