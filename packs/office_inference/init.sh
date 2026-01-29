#!/bin/bash
echo "Initializing Office Inference..."

echo "Select a model to download:"
echo "  1) Llama 3.2 (3B)   - Balanced, Fast, Low VRAM"
echo "  2) DeepSeek R1 (7B) - State-of-the-art Reasoning"
echo "  3) Qwen 2.5 (7B)    - Excellent for Coding & Math"
echo "  4) Exit"
echo ""
read -p "Select [1-3]: " CHOICE

TAG=""
case $CHOICE in
    1) TAG="llama3.2" ;;
    2) TAG="deepseek-r1" ;;
    3) TAG="qwen2.5" ;;
    *) echo "Exiting."; exit 0 ;;
esac

echo "Pulling $TAG..."
docker compose exec -it inference ollama pull "$TAG"

echo ""
echo "Model ready!"
echo "Access the Chat UI at: http://localhost:3000"
echo "Select '$TAG' from the dropdown at the top."
