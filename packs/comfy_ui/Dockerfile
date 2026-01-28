# Base Image: NVIDIA CUDA Runtime (Ubuntu 22.04 base for broad compatibility)
# We use 12.x to match modern consumer GPU drivers
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
# - python3.11: ComfyUI recommended
# - git, wget: For cloning managers/models
# - libgl1, libglib2.0-0: OpenCV requirements
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create standard user
RUN groupadd -r puget-app-pack && useradd -r -g puget-app-pack -m -d /home/puget-app-pack -s /bin/bash puget-app-pack

# Set up Workspace
WORKDIR /home/puget-app-pack/app

# Clone ComfyUI (Release branch/standard)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Install Python Requirements
# Note: We install system-wide or user-local for simplicity in this container
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip3 install --no-cache-dir -r requirements.txt

# Install 3D node dependencies (fixes nodes_load_3d.py import errors)
RUN pip3 install --no-cache-dir trimesh pygltflib numpy-stl

# Ensure standard data directories exist for volume mounting
# Using -p for idempotent creation (some may exist from git clone)
RUN mkdir -p models output input temp custom_nodes

# Fix permissions
RUN chown -R puget-app-pack:puget-app-pack /home/puget-app-pack

USER puget-app-pack

# Expose standard port
EXPOSE 8188

# Launch
CMD ["python3", "main.py", "--listen", "0.0.0.0"]
