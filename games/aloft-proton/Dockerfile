# ---------------------------------------------
# Steam Proton image
# ---------------------------------------------
FROM        ubuntu:24.04

LABEL       org.opencontainers.image.description="STEAM Proton-GE Image to use with Pelican/Pterodactyl Gamepanel"
LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later

# Env Setup
SHELL       [ "/bin/bash", "-c" ]

# setup apt and install needed packages
ARG         DEBIAN_FRONTEND=noninteractive
RUN         dpkg --add-architecture i386
RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
                nala \
                alsa-tools \
				ca-certificates \
                cabextract \
                curl \
                dbus \
                ffmpeg \
                file \
                git \
                gnupg \
                gnupg2 \
                gnutls-bin \
                iproute2 \
                locales \
                numactl \
                mesa-utils \
                net-tools \
                netcat-openbsd \
                openssl \
                pulseaudio \
                python3 \
                python3-pip \
                python3-setuptools \
                python3-venv \
                pipx \
                software-properties-common \
				steam \
                tar \
                tini \
                virt-what \
                wget \
                winbind \
                xauth \
                xvfb \
                lib32gcc-s1 \
                libao-common \
                libfreetype6 \
				libfreetype6:i386 \
                libsdl1.2debian \
                libsdl1.2debian:i386 \
                libsdl2-2.0-0 \
                libsdl2-2.0-0:i386 \
                libncurses5-dev:i386 \
                libncurses6 \
                libntlm0 \
				libnss-wrapper \
                libnss3 \
                libpulse0 \
                libgstreamer1.0-dev \
                libgstreamer-plugins-base1.0-dev \
                libgstreamer-plugins-bad1.0-dev \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-libav \
                gstreamer1.0-tools \
                gstreamer1.0-x \
                gstreamer1.0-alsa \
                gstreamer1.0-gl \
                gstreamer1.0-pulseaudio \
			&& apt-get clean \
			&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download Proton GE
RUN         curl -sLOJ $(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)
RUN         tar -xzf GE-Proton*.tar.gz -C /usr/local/bin/ --strip-components=1
RUN         rm GE-Proton*.*

# Proton Fix machine-id
RUN         rm -f /etc/machine-id
RUN         dbus-uuidgen --ensure=/etc/machine-id
RUN         rm /var/lib/dbus/machine-id
RUN         dbus-uuidgen --ensure

# Set up Winetricks
RUN	        wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
                && chmod +x /usr/sbin/winetricks
RUN         wget -q -O /usr/share/bash-completion/completions/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion

# Set the locale
RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            locale-gen
ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8

## install rcon
RUN         cd /tmp/ \
            && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
            && tar xvf rcon.tar.gz \
            && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/

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
