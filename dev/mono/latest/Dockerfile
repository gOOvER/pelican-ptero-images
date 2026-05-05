FROM        	debian:bookworm-slim

LABEL       	org.opencontainers.image.authors="info@goover.de"
LABEL       	org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       	org.opencontainers.image.licenses=AGPL-3.0-or-later
LABEL       	org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

# Update the repository and install needed packages
ARG         	DEBIAN_FRONTEND=noninteractive
RUN         	dpkg --add-architecture i386
RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
					nala \
					ca-certificates \
                    curl \
                    dbus \
                    dirmngr \
					fontconfig \
                    g++ \
                    gcc \
                    gcc-12-base \
                    gdb \
                    gettext \
                    git \
                    gnupg \
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
                    software-properties-common \
                    speex:i386 \
                    tar \
                    telnet \
                    tini \
                    tzdata \
                    wget \
                    lib32gcc-s1 \
                    lib32stdc++6 \
                    lib32tinfo6 \
                    libtinfo6:i386 \
                    lib32z1 \
                    libasound2 \
                    libatk1.0-0 \
                    libatomic1 \
                    libc++-dev \
                    libc++1 \
                    libc6 \
                    libc6:i386 \
                    libcurl3-gnutls \
                    libcurl3-gnutls:i386 \
                    libcurl4 \
                    libcurl4-gnutls-dev \
                    libcurl4-gnutls-dev:i386 \
                    libcurl4:i386 \
                    libfontconfig \
                    libgcc-s1 \
                    libgcc1 \
                    libgconf-2-4 \
                    libgdiplus \
                    libgtk2.0-0:i386 \
                    libjemalloc2 \
                    libjemalloc2:i386 \
                    libnss-wrapper \
                    libnss3 \
                    libpangocairo-1.0-0 \
                    libpulse-dev \
                    libpulse0 \
                    libsdl1.2-compat \
                    libsdl1.2-compat:i386 \
                    libsdl1.2debian \
                    libsdl1.2debian:i386 \
                    libsdl2-2.0-0 \
                    libsdl2-2.0-0:i386 \
                    libssl3 \
                    libssl3:i386 \
                    libstdc++6 \
                    libstdc++6:i386 \
                    libtcmalloc-minimal4 \
                    libtcmalloc-minimal4:i386 \
                    libtinfo6:i386 \
                    libxcomposite1 \
                    libxcursor1 \
                    libxdamage1 \
                    libxi6 \
                    libxrandr2 \
                    libxss1 \
                    libxtst6

#install mono
RUN         	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN        		sh -c 'echo "deb https://download.mono-project.com/repo/debian stable-buster main" > /etc/apt/sources.list.d/mono-official-stable.list'
RUN         	apt update
RUN         	apt install -y \
                	nala \
                	mono-complete

# Set the locale
RUN        		sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
           		locale-gen
ENV      		LANG=en_US.UTF-8
ENV       		LANGUAGE=en_US:en
ENV        		LC_ALL=en_US.UTF-8

## Setup user and working directory
RUN         	useradd -m -d /home/container -s /bin/bash container
USER        	container
ENV         	USER=container HOME=/home/container
WORKDIR     	/home/container

# Sets the default stop signal as wings can (currently) only send a kill or generic stop
STOPSIGNAL 		SIGINT

COPY        	--chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         	chmod +x /entrypoint.sh
ENTRYPOINT  	["/usr/bin/tini", "-g", "--"]
CMD         	["/entrypoint.sh"]
