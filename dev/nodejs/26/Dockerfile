FROM --platform=$TARGETOS/$TARGETARCH node:26-trixie-slim

LABEL org.opencontainers.image.authors="info@goover.de" \
      org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

ARG DEBIAN_FRONTEND=noninteractive

# Install required system packages and clean up afterwards to reduce image size
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        nala \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        curl \
        dnsutils \
        ffmpeg \
        g++ \
        git \
        gnupg \
        iproute2 \
        iputils-ping \
        libtool \
        locales \
        python3 \
        python3-dev \
        sqlite3 \
        tzdata \
        tini \
        zip \
        libnss3 \
        libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Update npm, install TypeScript, ts-node, and enable Corepack (for pnpm and Yarn)
RUN npm install -g npm@next-11 typescript ts-node tsx corepack && \
    corepack enable && \
    corepack prepare pnpm@latest --activate && \
    corepack prepare yarn@stable --activate

# Generate and set en_US.UTF-8 locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Create non-root user and working directory
RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Set stop signal for Docker (important for Pterodactyl)
STOPSIGNAL SIGINT

# Build argument to set entrypoint.sh location
ARG ENTRYPOINT_PATH=../entrypoint.sh

# Copy entrypoint from the specified path
COPY --chown=container:container ${ENTRYPOINT_PATH} /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use tini as init and run entrypoint script
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
