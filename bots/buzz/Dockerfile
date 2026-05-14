FROM --platform=$TARGETOS/$TARGETARCH node:24-trixie-slim

LABEL org.opencontainers.image.authors="info@goover.de" \
      org.opencontainers.image.source="https://github.com/gOOvER/own-pterodactyl-images" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.description="Node.js 24 image for Buzz Shop, Ember & Phantom Licence — Pelican / Pterodactyl"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        curl \
        dnsutils \
        g++ \
        git \
        gnupg \
        iproute2 \
        iputils-ping \
        libtool \
        locales \
        python3 \
        python3-dev \
        sqlite3 \
        tini \
        tzdata \
        zip && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@latest corepack && \
    corepack enable && \
    corepack prepare pnpm@latest --activate && \
    corepack prepare yarn@stable --activate

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
