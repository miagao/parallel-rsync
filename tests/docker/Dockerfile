FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    rsync \
    bc \
    coreutils \
    findutils \
    openssh-client \
    time \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /data/source /data/destination /var/log/rsync /scripts

# Create a non-root user for testing
RUN useradd -m -s /bin/bash testuser && \
    chown -R testuser:testuser /data /var/log/rsync /scripts

# Switch to non-root user
USER testuser

WORKDIR /scripts