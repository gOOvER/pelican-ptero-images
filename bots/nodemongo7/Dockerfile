FROM --platform=$TARGETOS/$TARGETARCH mongo:7-jammy

LABEL org.opencontainers.image.authors="info@goover.de" \
      org.opencontainers.image.source="https://github.com/gOOvER/pelican-ptero-images" \
      org.opencontainers.image.licenses=AGPL-3.0-or-later \
      org.opencontainers.image.description="Docker image for Pelican Hosting Panel and Pterodactyl"

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies, Node.js, Yarn & cleanup build deps (optimized for CI)
RUN apt-get update && \
    # Skip upgrade in container builds to save time
    apt-get install -y --no-install-recommends \
        nala \
        ca-certificates \
        curl \
        dnsutils \
        ffmpeg \
        git \
        gnupg \
        iproute2 \
        iputils-ping \
        locales \
        netcat-openbsd \
        python3 \
        python3-dev \
        sqlite3 \
        tini \
        tzdata \
		unzip \
        zip \
        libcairo2-dev \
        libgif-dev \
        libnss3 \
        libpango1.0-dev \
        librsvg2-dev \
        libsqlite3-dev \
    # temporäre Build-Tools für Node/Yarn
    && apt-get install -y --no-install-recommends \
        nala \
        autoconf \
        automake \
        build-essential \
        g++ \
        libtool \
        software-properties-common \
    && mkdir -p /etc/apt/keyrings \
    # Node.js 24.x installation
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
         | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
         > /etc/apt/sources.list.d/nodesource.list \
    # Yarn installation
    && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
         | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" \
         > /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y nodejs yarn \
    nala \
    # NPM + Essential packages (minimal installation)
    && npm install -g npm@latest --no-audit --no-fund --silent \
    && npm install -g corepack@latest --no-audit --no-fund --silent \
    && npm install -g json5 tsc typescript ts-node @types/node --no-audit --no-fund --silent \
    && corepack enable pnpm yarn \
    && corepack prepare pnpm@latest --activate \
    && corepack prepare yarn@stable --activate \
	# Install Bun (latest) - optimized for multi-arch
    && export BUN_INSTALL=/usr/local/bun \
    && curl -fsSL https://bun.sh/install | bash \
    && ln -sf /usr/local/bun/bin/bun /usr/local/bin/bun \
    # Locale configuration
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen \
    # CleanUp: Build-Dependencies entfernen (aggressive cleanup)
    && apt-get purge -y --auto-remove \
        autoconf \
        automake \
        build-essential \
        g++ \
        libtool \
        software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.npm ~/.cache

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MONGO_PORT=27017 \
    MONGO_DB=botdb \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

# Create user
RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Stop signal
STOPSIGNAL SIGINT

# Copy entrypoint
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
