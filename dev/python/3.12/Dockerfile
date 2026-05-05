FROM --platform=$TARGETOS/$TARGETARCH python:3.12-slim

LABEL org.opencontainers.image.authors="info@goover.de" \
      org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    USER=container \
    HOME=/home/container

# Install system dependencies and upgrade pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nala \
        ca-certificates \
        curl \
        default-libmysqlclient-dev \
        dnsutils \
        ffmpeg \
        g++ \
        gcc \
        git \
        iproute2 \
        locales \
        procps && \
    # Locale setup
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
    # Upgrade pip
    python -m pip install --no-cache-dir --upgrade pip && \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup non-root user
RUN useradd -m -d /home/container -s /bin/bash container
USER container
WORKDIR /home/container

# Entrypoint
COPY --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
