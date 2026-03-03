# Base Image: Python 3.11 Slim
FROM python:3.11-slim

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create standard user
RUN groupadd -r puget-app-pack && useradd -r -g puget-app-pack -m -d /home/puget-app-pack -s /bin/bash puget-app-pack

# Set up Workspace
WORKDIR /home/puget-app-pack/app

# Install Python Requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Fix permissions
RUN chown -R puget-app-pack:puget-app-pack /home/puget-app-pack

USER puget-app-pack

# Keep alive by default (overridden by docker-compose)
CMD ["tail", "-f", "/dev/null"]
