FROM        node:18-bookworm-slim

LABEL org.opencontainers.image.authors="Torsten Widmann - gOOvER - info@goover.de"
LABEL org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL org.opencontainers.image.description="Docker image for Pelican, Jexactyl & Pterodactyl"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

RUN         apt-get update \
            && apt-get -y upgrade \
            && apt-get -y --no-install-recommends install ffmpeg iproute2 git sqlite3 libsqlite3-dev python3 python3-dev ca-certificates dnsutils tzdata zip libnss3 libtool autoconf automake g++ build-essential \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/* \
            && useradd -d /home/container -m container

RUN         npm install -g npm@latest typescript@latest ts-node@latest

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         ["/bin/bash", "/entrypoint.sh"]
