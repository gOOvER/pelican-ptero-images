# ----------------------------------
# Mono Latest Image
# Minimum Panel Version: 1.2.x
# ----------------------------------
FROM    debian:bookworm-slim

LABEL   author="Torsten Widmann" maintainer="info@goover.de"

## install required packages
RUN         dpkg --add-architecture i386
RUN         apt update
RUN         apt install -y nala wget iproute2 gnupg2 software-properties-common libntlm0 winbind xvfb xauth python3 libncurses5-dev:i386 libncurses6 dbus libgdiplus lib32gcc-s1
RUN         apt install -y nala alsa-tools libpulse0 pulseaudio libpulse-dev libasound2 libao-common gnutls-bin gnupg locales numactl cabextract curl mesa-utils
RUN         apt install -y nala tar gcc g++ gdb libsdl1.2debian libfontconfig1 telnet net-tools netcat-openbsd tzdata psmisc lib32gcc-s1 libgcc1 lib32tinfo6 lib32z1 lib32stdc++6 libstdc++6 libgdiplus
RUN         apt install -y nala libpangocairo-1.0-0 libnss3 libgconf-2-4 libxi6 libxcursor1 libxss1 libxcomposite1 libasound2 libxdamage1 libxtst6 libatk1.0-0 libxrandr2 libcurl4
RUN         apt install -y nala libcurl4-gnutls-dev:i386 libssl3:i386 libcurl4:i386 libtinfo6:i386 libncurses5:i386 libcurl3-gnutls:i386 libsdl2-2.0-0:i386 libstdc++6:i386 libc6:i386
RUN         apt install -y nala python3 python3-dev python3-pip jq git libtcmalloc-minimal4 sed
RUN         apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN         sh -c 'echo "deb https://download.mono-project.com/repo/debian stable-buster main" > /etc/apt/sources.list.d/mono-official-stable.list'
RUN         apt update
RUN         apt install nala mono-complete mono-xsp4 mono-devel -y

# Download Proton GE
RUN     curl -sLOJ $(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)
RUN     tar -xzf GE-Proton*.tar.gz -C /usr/local/bin/ --strip-components=1
RUN     rm GE-Proton*.*

# Proton Fix machine-id
RUN     rm -f /etc/machine-id
RUN     dbus-uuidgen --ensure=/etc/machine-id
RUN     rm /var/lib/dbus/machine-id
RUN     dbus-uuidgen --ensure

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

COPY        ./../entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]
