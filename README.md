# Puget Systems Docker App Pack

A standardized, high-performance starter template system for AI and engineering workflows on Puget Systems workstations.

## Overview

This repository uses an **App Pack** architecture. It provides specialized "Flavors" (Stacks) that serve as reliable foundations for your containerized applications, from basic Python scripts to complex AI Agent Swarms.

**Supported Hardware**:
*   **Standard**: Any x86_64 / ARM64 System (Mac/PC)
*   **Accelerated**: Puget Systems Workstations with NVIDIA GPUs (CUDA 12.x support)
*   **High-Performance**: Workstations with 700GB+ VRAM (H100/Instinct) via overrides

## Available Flavors

### 1. Base (LTS)
*   **Target**: General Purpose Development
*   **OS**: Ubuntu 24.04 LTS
*   **Components**: `git`, `python3`, `pip`
*   **Best For**: Scripts, Data Processing, Cleaning

### 2. ComfyUI (Creative)
*   **Target**: Generative AI & Image Synthesis
*   **Base**: NVIDIA CUDA 12.4 Runtime (Ubuntu 22.04)
*   **Stack**: ComfyUI (Latest), Manager-Ready
*   **Persistence**: Auto-maps `./models` and `./output` to host for easy file management.

### 3. Office Inference (Swarm)
*   **Target**: Local AI Agents & Chatbots
*   **Architecture**: Multi-Service Swarm
    *   **Brain**: **AutoGen** (Microsoft) Agent Container
    *   **Inference**: **Ollama** (Default) or **vLLM** (High-Performance)
*   **Networking**: Internal low-latency Docker network (`puget_swarm_net`)

---

## Quick Start

### Installation

1.  **One-Line Install (Recommended)**:
    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Puget-Systems/puget-docker-app-pack/main/setup.sh)"
    ```

2.  **Manual Install**:
    Clone this repository and run:
    ```bash
    ./install.sh
    ```
2.  **Select Your Flavor**:
    The wizard will prompt you to choose the stack that fits your use case.
3.  **Deploy**:
    ```bash
    cd my-new-app
    docker compose up -d
    ```

### High-End Hardware Override (700GB+ VRAM)
To switch the **Office Inference** stack from Ollama to **vLLM** for maximum throughput on H100s, add a `docker-compose.override.yml` to your installed directory:

```yaml
services:
  inference:
    image: vllm/vllm-openai:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Repository Structure

```text
.
├── install.sh             # Universal Interactive Installer
├── packs/                 # Flavor Templates
│   ├── docker-base/       # Ubuntu 24.04 LTS Foundation
│   ├── comfy_ui/          # Creative Stack (CUDA + ComfyUI)
│   └── office_inference/  # Swarm Stack (AutoGen + Ollama)
└── README.md
```
