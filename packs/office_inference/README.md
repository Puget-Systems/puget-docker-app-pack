# Office Inference Pack

The Office Inference pack provides a cutting-edge "Office LLM" stack, optimized for privacy and local control.

## Components

1.  **The Engine (Ollama)**: Local inference server with GPU acceleration.
2.  **The Interface (Open WebUI)**: ChatGPT-like interface for chatting and RAG (document upload).
3.  **The Brain (AutoGen)**: *Advanced Users*. An agent workflow engine for creating "Swarms of Experts".

## Quick Start

1.  Start the stack:
    ```bash
    docker compose up -d
    ```

2.  (First Run Only) Initialize a model:
    ```bash
    ./init.sh
    ```
    Or manually: `docker compose exec inference ollama pull llama3.2`

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
