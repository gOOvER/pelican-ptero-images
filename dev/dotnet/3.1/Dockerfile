FROM        --platform=$TARGETOS/$TARGETARCH debian:bullseye-slim

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.title="Pelican Image - .NET Core SDK 3.1"
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"
LABEL       org.opencontainers.image.vendor="gOOvER"
LABEL       org.opencontainers.image.url="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.documentation="https://github.com/gOOvER/pelican-ptero-images/blob/main/README.md"
LABEL       org.opencontainers.image.base.name="debian:bullseye-slim"

ARG         DEBIAN_FRONTEND=noninteractive

## Install dependencies, .NET SDK, configure locale, and cleanup in single layer
RUN         apt-get update \
            && apt-get upgrade -y \
            && apt-get install -y --no-install-recommends \
                acl \
                apt-transport-https \
                ca-certificates \
                curl \
                gettext-base \
                gnupg \
                iproute2 \
                libc6 \
                libgdiplus \
                locales \
                sqlite3 \
                tini \
                wget \
            ## Install .NET SDK 3.1 (EOL - legacy support only)
            && wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh \
            && chmod +x /tmp/dotnet-install.sh \
            && /tmp/dotnet-install.sh -i /usr/share/dotnet -c 3.1 \
            && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
            ## Configure locale
            && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
            && locale-gen \
            ## Cleanup
            && rm -f /tmp/dotnet-install.sh \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Environment
ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8
ENV         DOTNET_ROOT=/usr/share/dotnet

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL  SIGINT

COPY        --chown=container:container --chmod=755 ../entrypoint.sh /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
