FROM      --platform=$BUILDPLATFORM debian:stable-slim

LABEL     author="Torsten Widmann" maintainer="info@goover.de"
LABEL     org.opencontainers.image.source="https://github.com/pterodactyl/yolks"
LABEL     org.opencontainers.image.licenses=MIT

ENV       DEBIAN_FRONTEND=noninteractive

##    update base packages
RUN       apt update \
          &&   apt upgrade -y

##    install dependencies
RUN   apt install -y nala ffmpeg curl python3 iproute2 libjemalloc2

# Install latest youtube-dl
RUN   curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
RUN   chmod a+rx /usr/local/bin/youtube-dl

RUN   update-alternatives --install  /usr/bin/python python /usr/bin/python3 1000

RUN   useradd -m -d /home/container container

USER   container
ENV    USER=container HOME=/home/container
WORKDIR /home/container

COPY  ./entrypoint.sh /entrypoint.sh
CMD   ["/bin/bash", "/entrypoint.sh"]
