ARG         JAVA_VERSION=21
FROM        --platform=$TARGETOS/$TARGETARCH ghcr.io/graalvm/jdk-community:${JAVA_VERSION}

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

RUN         microdnf update -y --nodocs --setopt=install_weak_deps=0 \
            && microdnf install -y --nodocs --setopt=install_weak_deps=0 \
                ca-certificates \
                curl \
                fontconfig \
                freetype \
                gcc \
                gcc-c++ \
                gettext \
                git \
                glibc-langpack-en \
                glibc-locale-source \
                iproute \
                libstdc++ \
                lsof \
                openssl \
                sqlite \
                tar \
                tzdata \
            && microdnf clean all \
            && rm -rf /var/cache/yum /var/log/*

ENV         LC_ALL=en_US.UTF-8
ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US.UTF-8

RUN         adduser --home-dir /home/container container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        --chmod=755 ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]
