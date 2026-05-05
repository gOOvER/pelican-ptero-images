FROM debian:trixie-slim

LABEL author="David Wolfe (Red-Thirten)" \
      maintainer="red_thirten@yahoo.com"
LABEL org.opencontainers.image.source="https://github.com/pelican-eggs/yolks"

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies in a single layer to improve caching and reduce image size.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    nala \
    ca-certificates \
    curl \
    tzdata \
    locales \
    iproute2 \
    gettext-base \
    libssl-dev \
    lib32gcc-s1 \
    libsdl2-2.0-0 \
    libsdl2-2.0-0:i386 \
    libstdc++6 \
    libstdc++6:i386 \
    lib32stdc++6 \
    libnss-wrapper \
    libnss-wrapper:i386 \
    libtbbmalloc2 \
    libtbbmalloc2:i386 \
    tini \
 && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 && localedef -i en_US -f UTF-8 en_US.UTF-8 || true \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

# Copy passwd template and prepare NSS wrapper files (root-owned operations)
COPY passwd.template /passwd.template
RUN touch /tmp/passwd /tmp/group \
 && chgrp 0 /tmp/passwd /tmp/group \
 && chmod g+rw /tmp/passwd /tmp/group

# Create an unprivileged user and set working directory
RUN useradd -m -d /home/container -s /bin/bash container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Copy entrypoint as the container user and make it executable
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use Tini as PID 1 to forward signals properly
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
