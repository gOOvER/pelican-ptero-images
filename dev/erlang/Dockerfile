ARG ERLANG_VERSION=24
FROM        --platform=$BUILDPLATFORM erlang:${ERLANG_VERSION}-alpine

LABEL       author="Pascal Zarrad" maintainer="p.zarrad@outlook.de"
LABEL       org.opencontainers.image.source="https://github.com/pterodactyl/yolks"
LABEL       org.opencontainers.image.licenses=AGPL

RUN         apk add --update --no-cache ca-certificates curl git openssl sqlite tar tzdata \
				&& adduser -D -h /home/container container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/ash", "/entrypoint.sh" ]
