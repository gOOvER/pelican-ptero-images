FROM        ubuntu:24.04

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"


ENV         DEBIAN_FRONTEND=noninteractive

RUN         dpkg --add-architecture i386
RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
                    nala \
                    ca-certificates \
                    curl \
                    dbus \
                    dirmngr \
                    aspnetcore-runtime-8.0 \
                    dotnet-sdk-8.0 \
                    g++ \
                    gcc \
                    gdb \
                    gettext \
                    git \
                    gnupg \
                    iproute2 \
                    iproute2 \
                    jq \
                    locales \
                    mesa-utils \
                    net-tools \
                    netcat-openbsd \
                    numactl \
                    psmisc \
                    python3 \
                    python3-dev \
                    python3-pip \
                    sed \
                    speex:i386 \
                    tar \
                    telnet \
                    tini \
                    tzdata \
                    wget \
                    lib32gcc-s1-amd64-cross \
                    libgcc-s1-amd64-cross \
                    lib32stdc++6 \
                    lib32tinfo6 \
                    lib32z1 \
                    libatk1.0-0 \
                    libatomic1 \
                    libc++-dev \
                    libc++1 \
                    libc6 \
                    libc6:i386 \
                    libcurl3-gnutls \
                    libcurl3-gnutls:i386 \
                    libcurl4 \
                    libcurl4-gnutls-dev:i386 \
                    libcurl4:i386 \
                    libfontconfig \
					libnss-wrapper \
                    libgcc1 \
                    libgdiplus \
                    libgtk2.0-0:i386 \
                    libicu74 \
                    libnss3 \
                    libpangocairo-1.0-0 \
                    libpulse-dev \
                    libpulse0 \
                    libsdl1.2debian \
                    libsdl1.2debian:i386 \
                    libsdl2-2.0-0 \
                    libsdl2-2.0-0:i386 \
                    libssl3 \
                    libssl3:i386 \
                    libstdc++6 \
                    libstdc++6:i386 \
                    libtcmalloc-minimal4 \
                    libtinfo6:i386 \
                    libxcomposite1 \
                    libxcursor1 \
                    libxdamage1 \
                    libxi6 \
                    libxrandr2 \
                    libxss1 \
                    libxtst6 && \
			rm -rf /var/lib/apt/lists/*

## install rcon
RUN         cd /tmp/ \
            && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
            && tar xvf rcon.tar.gz \
            && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/

# Set the locale
RUN         	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            	locale-gen
ENV        		LANG=en_US.UTF-8
ENV         	LANGUAGE=en_US:en
ENV         	LC_ALL=en_US.UTF-8

# Set the locale
RUN       	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
           	locale-gen

ENV     	LANG=en_US.UTF-8 \
       		LANGUAGE=en_US:en \
        	LC_ALL=en_US.UTF-8

# Sets the default stop signal as wings can (currently) only send a kill or generic stop
STOPSIGNAL SIGINT

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
