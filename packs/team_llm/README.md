# Team LLM Pack

Production-grade local LLM server for teams. Multi-GPU tensor parallelism with vLLM, serving an OpenAI-compatible API.

## Components

1.  **The Engine (vLLM)**: High-throughput inference with tensor parallelism across multiple GPUs.
2.  **The Interface (Open WebUI)**: ChatGPT-like interface connected via OpenAI API.
3.  **The Brain (AutoGen)**: *Advanced Users*. Agent workflow engine for "Swarms of Experts".

## When to Use This Pack

- **Multiple users** sharing one workstation or server
- You need **multi-GPU tensor parallelism** (vLLM splits computation, not just memory)
- You're serving a **single model in production** (less model swapping, more throughput)

> For personal use with easy model swapping, see the **Personal LLM** pack.

## Quick Start

1.  Run the setup wizard (detects GPUs, picks a model):
    ```bash
    ./init.sh
    ```

2.  Or configure manually via `.env`:
    ```bash
    MODEL_ID=Qwen/Qwen3-32B
    GPU_COUNT=2
    MAX_CONTEXT=32768
    ```

3.  Start the stack:
    ```bash
    docker compose up -d
    ```

4.  Access the Chat UI: [http://localhost:3000](http://localhost:3000)
5.  API endpoint: [http://localhost:8000/v1](http://localhost:8000/v1)

## Model Reference

| Model | HuggingFace ID | VRAM (FP16) | Best For |
|---|---|---|---|
| Qwen 3 8B | `Qwen/Qwen3-8B` | ~16 GB | Fast tasks |
| Qwen 3 32B | `Qwen/Qwen3-32B` | ~64 GB | General quality |
| DeepSeek R1 70B | `deepseek-ai/DeepSeek-R1-Distill-Llama-70B` | ~140 GB | Reasoning |
| Llama 4 Scout | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | ~109 GB | Multimodal |

> **Note**: VRAM above is for FP16. vLLM supports quantization (AWQ, GPTQ) for lower VRAM footprints. Add `--quantization awq` to the compose command if needed.

## Changing Models

Edit `MODEL_ID` in `.env` and restart:

```bash
# Edit .env
MODEL_ID=deepseek-ai/DeepSeek-R1-Distill-Llama-70B
GPU_COUNT=2

# Restart
docker compose down && docker compose up -d
```

## Advanced: The "Brain" (AutoGen)

Same as Personal LLM, but the brain connects via OpenAI API to vLLM:

```bash
docker compose exec brain bash
python examples/group_chat.py
```
