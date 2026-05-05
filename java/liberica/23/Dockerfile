FROM        --platform=$TARGETOS/$TARGETARCH bellsoft/liberica-openjdk-debian:23

LABEL       org.opencontainers.image.authors="info@goover.de"
LABEL       org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images"
LABEL       org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"
LABEL       org.opencontainers.image.licenses=AGPL-3.0-or-later


ENV         DEBIAN_FRONTEND=noninteractive

RUN 		apt-get update \
			&& apt-get upgrade -y \
			&& apt-get install -y --no-install-recommends \
				nala \
				build-essential \
				ca-certificates \
				curl \
				font-manager \
				fontconfig \
				git \
				iproute2 \
				ipset \
				locales \
				lsof \
				openssl \
				sqlite3 \
				tar \
				tzdata \
				libfreetype6 \
				libstdc++6 \
			&& apt-get clean \
			&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Set the locale
RUN       	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
           	locale-gen
ENV      	LANG=en_US.UTF-8
ENV        	LANGUAGE=en_US:en
ENV        	LC_ALL=en_US.UTF-8

## Setup user and working directory
RUN     	useradd -m -d /home/container -s /bin/bash container
USER    	container
ENV     	USER=container HOME=/home/container
WORKDIR 	/home/container

COPY        ./../entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]
