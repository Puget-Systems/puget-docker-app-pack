# Base Image: Ubuntu 24.04 LTS (Noble Numbat)
# Matching standard "Guest VM" environment
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential development tools
# - git, curl, vim: Basic file/network tools
# - python3, python3-pip: Standard runtime for this App Pack
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create standard user and group "puget-app-pack"
# This prevents permission issues when adhering to the standard non-root workflow
RUN groupadd -r puget-app-pack && useradd -r -g puget-app-pack -m -d /home/puget-app-pack -s /bin/bash puget-app-pack

# Set up the standardized project root
WORKDIR /home/puget-app-pack/app

# Ensure the non-root user owns the workspace
RUN chown -R puget-app-pack:puget-app-pack /home/puget-app-pack

# Switch to non-root user
USER puget-app-pack

# Default command to keep the container running for development
CMD ["tail", "-f", "/dev/null"]
