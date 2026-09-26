ARG ARCH_TAG=latest
FROM        --platform=$BUILDPLATFORM archlinux:${ARCH_TAG}

LABEL       org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

RUN 		pacman -Fy --noconfirm
RUN 		pacman -Syu --noconfirm
RUN         pacman -Sy --noconfirm ca-certificates tzdata

RUN 		useradd -D -h /home/container container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/ash", "/entrypoint.sh" ]
