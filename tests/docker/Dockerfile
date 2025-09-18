FROM ubuntu:22.04

# Install required packages (minimal for CI speed)
RUN apt-get update && apt-get install -y \
    rsync \
    bc \
    coreutils \
    findutils \
    time \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create necessary directories
RUN mkdir -p /data/source /data/destination /var/log/rsync /scripts

# Create a non-root user for testing
RUN useradd -m -s /bin/bash testuser && \
    chown -R testuser:testuser /data /var/log/rsync /scripts

# Switch to non-root user
USER testuser

WORKDIR /scripts