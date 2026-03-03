# Personal LLM Pack

Local AI assistant for individual use. Easy model management — pull, swap, and chat with any open-source model.

## Components

1.  **The Engine (Ollama)**: Local inference server with GPU acceleration and one-command model management.
2.  **The Interface (Open WebUI)**: ChatGPT-like interface for chatting and RAG (document upload).
3.  **The Brain (AutoGen)**: *Advanced Users*. An agent workflow engine for creating "Swarms of Experts".

## When to Use This Pack

- **Single user** workstation or personal machine
- You want to **browse and swap models** easily (`ollama pull qwen3:32b`)
- Your model fits on a **single GPU** (up to ~90 GB for RTX PRO 6000)

> For multi-user serving or multi-GPU tensor parallelism, see the **Team LLM** pack.

## Quick Start

1.  Start the stack:
    ```bash
    docker compose up -d
    ```

2.  (First Run Only) Initialize a model:
    ```bash
    ./init.sh
    ```
    Or manually: `docker compose exec inference ollama pull qwen3:32b`

3.  Access the Chat UI: [http://localhost:3000](http://localhost:3000)

## Advanced: The "Brain" (AutoGen)

The `brain` container is a headless Python environment pre-loaded with `pyautogen`. It connects to the local Ollama instance via the internal network.

To run the example swarm:

```bash
# Enter the brain container
docker compose exec brain bash

# Run the example
python examples/group_chat.py
```
