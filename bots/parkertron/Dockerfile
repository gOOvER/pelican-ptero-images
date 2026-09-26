FROM        --platform=$TARGETOS/$TARGETARCH alpine:latest

LABEL author="Michael Parker" maintainer="parker@pterodactyl.io"

RUN         apk add --update --no-cache git curl lua-stdlib lua musl-dev g++ libc-dev tesseract-ocr tesseract-ocr-dev \
            && adduser -D -h /home/container container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/ash", "/entrypoint.sh"]
