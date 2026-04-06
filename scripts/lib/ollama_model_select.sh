#!/bin/bash
# Puget Systems — Shared Ollama Model Selection
# Source this file; do not execute directly.
#
# Prerequisites: source gpu_detect.sh and call detect_gpus first.
#   Required globals: GPU_COUNT, TOTAL_VRAM, VRAM_GB
#   Required colors:  GREEN, BLUE, YELLOW, RED, NC
#
# Usage:
#   show_ollama_model_menu          # prints the numbered model list
#   select_ollama_model <choice>    # sets OLLAMA_* output vars, returns 0/1/2

show_ollama_model_menu() {
    echo "  1) Qwen 3 (8B)           - Fast, Low VRAM (~5 GB)"

    if [ "$TOTAL_VRAM" -ge 20 ]; then
        echo "  2) Qwen 3 (32B)          - Best Quality, Single GPU (~20 GB) [Recommended]"
    else
        echo -e "  2) Qwen 3 (32B)          - ${RED}Requires ~20 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    if [ "$TOTAL_VRAM" -ge 42 ]; then
        echo "  3) DeepSeek R1 (70B)     - Flagship Reasoning, Dual GPU (~42 GB)"
    else
        echo -e "  3) DeepSeek R1 (70B)     - ${RED}Requires ~42 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    if [ "$TOTAL_VRAM" -ge 63 ]; then
        echo "  4) Llama 4 Scout         - Multimodal (text+image), Dual GPU (~63 GB)"
    else
        echo -e "  4) Llama 4 Scout         - ${RED}Requires ~63 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    if [ "$TOTAL_VRAM" -ge 24 ]; then
        echo "  5) Nemotron 3 Nano (30B) - NVIDIA MoE Reasoning, Single GPU (~24 GB)"
    else
        echo -e "  5) Nemotron 3 Nano (30B) - ${RED}Requires ~24 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    if [ "$TOTAL_VRAM" -ge 96 ]; then
        echo "  6) Nemotron 3 Super      - NVIDIA Flagship MoE, Multi-GPU (~96 GB)"
    else
        echo -e "  6) Nemotron 3 Super      - ${RED}Requires ~96 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    if [ "$TOTAL_VRAM" -ge 20 ]; then
        echo "  7) Gemma 4 (31B)         - Google, Dense Instruct, Single GPU (~20 GB)"
    else
        echo -e "  7) Gemma 4 (31B)         - ${RED}Requires ~20 GB VRAM (you have ${TOTAL_VRAM} GB)${NC}"
    fi

    echo "  8) Skip                  - I'll download models later"
}

# select_ollama_model <choice>
#   Sets: OLLAMA_MODEL_TAG, OLLAMA_MODEL_VRAM_GB
#   Returns: 0 = model selected, 1 = VRAM insufficient, 2 = skipped
select_ollama_model() {
    local choice="$1"

    OLLAMA_MODEL_TAG=""
    OLLAMA_MODEL_VRAM_GB=0

    case $choice in
        1) OLLAMA_MODEL_TAG="qwen3:8b";          OLLAMA_MODEL_VRAM_GB=5 ;;
        2) OLLAMA_MODEL_TAG="qwen3:32b";          OLLAMA_MODEL_VRAM_GB=20 ;;
        3) OLLAMA_MODEL_TAG="deepseek-r1:70b";    OLLAMA_MODEL_VRAM_GB=42 ;;
        4) OLLAMA_MODEL_TAG="llama4:scout";        OLLAMA_MODEL_VRAM_GB=63 ;;
        5) OLLAMA_MODEL_TAG="nemotron-3-nano:30b"; OLLAMA_MODEL_VRAM_GB=24 ;;
        6) OLLAMA_MODEL_TAG="nemotron-3-super";    OLLAMA_MODEL_VRAM_GB=96 ;;
        7) OLLAMA_MODEL_TAG="gemma4:31b";          OLLAMA_MODEL_VRAM_GB=20 ;;
        *) return 2 ;;
    esac

    # VRAM gate: warn and block if insufficient
    if [ "$TOTAL_VRAM" -lt "$OLLAMA_MODEL_VRAM_GB" ]; then
        echo -e "${RED}✗ ${OLLAMA_MODEL_TAG} requires ~${OLLAMA_MODEL_VRAM_GB} GB VRAM (you have ${TOTAL_VRAM} GB).${NC}"
        echo "  Select a smaller model or add more GPUs."
        return 1
    fi

    return 0
}
