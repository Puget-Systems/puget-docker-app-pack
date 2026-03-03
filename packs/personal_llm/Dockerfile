# Base Image: Python 3.11 Slim (Standard for Agentic Frameworks)
# Keeping it slim but capable
FROM python:3.11-slim

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install System Dependencies
# - curl/build-essential: For compiling certain python extensions
# - git: For version control
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create standard user
RUN groupadd -r puget-app-pack && useradd -r -g puget-app-pack -m -d /home/puget-app-pack -s /bin/bash puget-app-pack

# Set up Workspace
WORKDIR /home/puget-app-pack/app

# Install AutoGen and standard Agentic tools
# - pyautogen: The core framework
# - ollama: Client library for local inference
# - langchain / chromadb: Optional but common for RAG
RUN pip install --no-cache-dir \
    pyautogen \
    ollama \
    pydantic \
    requests \
    termcolor

# Create source directory
RUN mkdir src

# Fix permissions
RUN chown -R puget-app-pack:puget-app-pack /home/puget-app-pack

USER puget-app-pack

# Default command: standardized to keep container alive for dev
CMD ["tail", "-f", "/dev/null"]
