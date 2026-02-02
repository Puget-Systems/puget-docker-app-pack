#!/bin/bash

# Puget Systems Docker App Pack - Universal Installer
# Standards: Ubuntu 24.04 LTS target, /home/puget-app-pack/app pathing

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Puget Systems Docker App Pack - Universal Installer${NC}"
echo -e "${BLUE}============================================================${NC}"

# 0. Prerequisite Checks
echo -e "\n${YELLOW}[Preflight] Checking dependencies...${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed.${NC}"
    read -p "  Would you like to install Docker now? (Y/n): " INSTALL_DOCKER
    if [[ "$INSTALL_DOCKER" != "n" && "$INSTALL_DOCKER" != "N" ]]; then
        echo -e "${BLUE}Installing Docker (Official Docker CE)...${NC}"
        
        # 1. Remove any old/conflicting packages
        sudo apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true
        
        # 2. Install prerequisites
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg
        
        # 3. Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        # 4. Add the Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # 5. Install Docker Engine + Compose Plugin
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # 6. Add user to docker group
        sudo usermod -aG docker $USER
        
        echo -e "${GREEN}✓ Docker installed.${NC}"
        echo -e "${YELLOW}  Note: You may need to log out and back in for docker group changes.${NC}"
    fi
else
    echo -e "${GREEN}✓ Docker found.${NC}"
fi

# Reload with docker group if needed
if command -v docker &> /dev/null; then
    if groups | grep -q "\bdocker\b"; then
        # User is in group active session, good.
        :
    else
        if id -nG "$USER" | grep -qw "docker"; then
            echo -e "${YELLOW}User added to docker group but session not updated.${NC}"
            echo -e "${BLUE}Reloading installer with group permissions...${NC}"
            exec sg docker -c "$0 $@"
        fi
    fi
fi

# Check for Docker Compose (required for all stacks)
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose plugin is not installed.${NC}"
    echo "  All stacks require 'docker compose' to run."
    read -p "  Would you like to install Docker Compose plugin now? (Y/n): " INSTALL_COMPOSE
    if [[ "$INSTALL_COMPOSE" != "n" && "$INSTALL_COMPOSE" != "N" ]]; then
        echo -e "${BLUE}Installing Docker Compose plugin...${NC}"
        
        # Ensure Docker repo is configured
        if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
        fi
        
        sudo apt install -y docker-compose-plugin
        echo -e "${GREEN}✓ Docker Compose plugin installed.${NC}"
    else
        echo -e "${RED}Cannot continue without Docker Compose.${NC}"
        exit 1
    fi
else
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ Docker Compose found: ${COMPOSE_VERSION}${NC}"
fi

# Docker Group Warning (critical for Ubuntu)
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}⚠ IMPORTANT (Ubuntu/Debian users):${NC}"
echo -e "  Docker commands require ${RED}sudo${NC} unless your user is in the 'docker' group."
echo -e "  If you haven't already, run: ${GREEN}sudo usermod -aG docker \$USER${NC}"
echo -e "  Then ${RED}LOG OUT${NC} and back in for changes to take effect."
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for NVIDIA Drivers (required for GPU stacks)
# We check if nvidia-smi exists AND returns success (0)
if ! command -v nvidia-smi &> /dev/null || ! nvidia-smi &> /dev/null; then
    echo -e "${RED}✗ NVIDIA drivers not detected (or not active).${NC}"
    echo "  GPU-accelerated stacks (ComfyUI, Office Inference) require NVIDIA drivers 550+."
    
    # Offer automated installation
    read -p "  Would you like to install the NVIDIA drivers (550) now? (Y/n): " INSTALL_DRIVERS
    if [[ "$INSTALL_DRIVERS" != "n" && "$INSTALL_DRIVERS" != "N" ]]; then
        echo -e "${BLUE}Installing NVIDIA drivers (550)...${NC}"
        sudo apt update && sudo apt install -y nvidia-driver-550
        
        echo -e "${YELLOW}⚠ IMPORTANT: Drivers installed.${NC}"
        echo -e "${YELLOW}  You MUST REBOOT your system before the GPU will be available.${NC}"
        echo "  Please reboot and run this installer again."
        exit 0
    else
        echo "  Skipping driver installation. GPU containers may fail to start."
    fi
else
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    echo -e "${GREEN}✓ NVIDIA Driver found: $DRIVER_VERSION${NC}"
fi

# Check for NVIDIA Container Toolkit (required for GPU access)
if ! dpkg -l nvidia-container-toolkit &> /dev/null 2>&1; then
    echo -e "${RED}✗ NVIDIA Container Toolkit is not installed.${NC}"
    echo "  This is required for GPU passthrough to containers."
    read -p "  Would you like to install NVIDIA Container Toolkit now? (Y/n): " INSTALL_NVIDIA
    if [[ "$INSTALL_NVIDIA" != "n" && "$INSTALL_NVIDIA" != "N" ]]; then
        echo -e "${BLUE}Installing NVIDIA Container Toolkit...${NC}"
        # Add NVIDIA repo
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt update && sudo apt install -y nvidia-container-toolkit
        echo -e "${GREEN}✓ NVIDIA Container Toolkit installed.${NC}"
    fi
else
    echo -e "${GREEN}✓ NVIDIA Container Toolkit found.${NC}"
fi

# ALWAYS ensure Docker runtime is configured for NVIDIA (even if toolkit was pre-installed)
if command -v nvidia-ctk &> /dev/null && command -v docker &> /dev/null; then
    # Check if nvidia runtime is configured in Docker
    if ! docker info 2>/dev/null | grep -q "nvidia"; then
        echo -e "${BLUE}Configuring Docker for NVIDIA GPU access...${NC}"
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        
        # Wait for Docker to restart
        echo "Waiting for Docker to restart..."
        for i in {1..10}; do
            if docker info &> /dev/null; then
                break
            fi
            sleep 1
        done
        
        echo -e "${GREEN}✓ Docker GPU runtime configured.${NC}"
    fi

    # Verify generic GPU access
    echo "Verifying GPU access in Docker..."
    if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✓ GPU accessible from Docker.${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: GPU check failed. Containers may not detect the GPU.${NC}"
        echo -e "${YELLOW}  This might be due to a missing reboot or driver issue.${NC}"
    fi
fi

# Re-check after potential installs
if ! command -v docker &> /dev/null; then
    echo -e "\n${RED}Docker is still not available. Cannot continue.${NC}"
    echo "Please install Docker manually and run this installer again."
    exit 1
fi

# --- Configuration ---

# Resolve the directory where this script resides to find the packs
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PACKS_DIR="$SCRIPT_DIR/packs"

if [ ! -d "$PACKS_DIR" ]; then
   echo -e "${RED}Error: 'packs' directory not found at $PACKS_DIR!${NC}"
   exit 1
fi

OPTIONS=($(ls "$PACKS_DIR"))

if [ ${#OPTIONS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No packs found in $PACKS_DIR.${NC}"
    exit 1
fi

# 1. Flavor Selection
echo -e "\n${YELLOW}[Step 1] Select Application Flavor${NC}"
echo "Different flavors are optimized for different use cases:"
echo "--------------------------------------------------------"

PS3="Select a flavor (enter number): "
select FLAVOR in "${OPTIONS[@]}"; do
    if [ -n "$FLAVOR" ]; then
        echo -e "Selected Flavor: ${GREEN}$FLAVOR${NC}"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# 2. Directory Setup
DEFAULT_DIR="${FLAVOR:-my-puget-app}"
echo -e "\n${YELLOW}[Step 2] Configuration${NC}"
read -p "Enter installation directory name [${DEFAULT_DIR}]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Warning: Directory '$INSTALL_DIR' already exists.${NC}"
    read -p "Continue and potentially overwrite files? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Installation aborted."
        exit 1
    fi
else
    mkdir -p "$INSTALL_DIR"
fi

# 3. Feature Selection (Placeholder for Phase 2)
# Future: Read 'features.json' from pack and prompt for mixins
echo -e "\n${YELLOW}[Step 3] Customization${NC}"
echo "Standard configuration selected."

# 4. Installation
echo -e "\n${YELLOW}[Step 4] Installing...${NC}"

# Copy Core Pack Files
cp -r "$PACKS_DIR/$FLAVOR/." "$INSTALL_DIR/"

# Create standard .env if it doesn't exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo "Creating default .env..."
    echo "PUGET_APP_NAME=$INSTALL_DIR" > "$INSTALL_DIR/.env"
fi

echo -e "${GREEN}Success! Application installed to '$INSTALL_DIR'.${NC}"

# Per-Flavor Post-Install Guidance
echo -e "\n${YELLOW}[Post-Install: $FLAVOR]${NC}"
case $FLAVOR in
    comfy_ui)
        echo "ComfyUI requires AI models to generate images."
        
        # Create required directories with write permissions
        # This prevents Docker from creating them as root and ensures the container user can write
        echo -e "${BLUE}Ensuring data directories exist and are writable...${NC}"
        COMFY_DIRS=("models" "models/checkpoints" "output" "input" "temp" "custom_nodes")
        for dir in "${COMFY_DIRS[@]}"; do
            target="$INSTALL_DIR/$dir"
            if [ ! -d "$target" ]; then
                mkdir -p "$target"
            fi
            # Allow container user to write (since UID might not match host)
            chmod 777 "$target"
        done

        echo ""
        echo "Select a Creative Stack for your workflow:"
        echo "  1) Pro Image  (Flux.1 Schnell ~12GB) - SOTA Image Generation"
        echo "  2) Pro Video  (LTX-Video 2B   ~4GB)  - Best Open Source Video Model"
        echo "  3) Standard   (SDXL Base 1.0  ~6GB)  - Reliable, Broad Compatibility"
        echo "  4) Skip       - I'll download models myself"
        echo ""
        read -p "Select a stack [1-4]: " STACK_CHOICE
        
        case $STACK_CHOICE in
            1)
                echo -e "${BLUE}Downloading Flux.1 Schnell (Pro Image Stack)...${NC}"
                mkdir -p "$INSTALL_DIR/models/checkpoints"
                wget -q --show-progress -P "$INSTALL_DIR/models/checkpoints/" \
                    "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors"
                echo -e "${GREEN}✓ Flux.1 Schnell downloaded.${NC}"
                ;;
            2)
                echo -e "${BLUE}Downloading LTX-Video 2B (Pro Video Stack)...${NC}"
                mkdir -p "$INSTALL_DIR/models/checkpoints"
                wget -q --show-progress -P "$INSTALL_DIR/models/checkpoints/" \
                    "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.5.safetensors"
                echo -e "${GREEN}✓ LTX-Video downloaded.${NC}"
                echo -e "${YELLOW}Note: You will need to install 'ComfyUI-LTXVideo' custom nodes via ComfyUI Manager.${NC}"
                ;;
            3)
                echo -e "${BLUE}Downloading SDXL Base 1.0 (Standard Stack)...${NC}"
                mkdir -p "$INSTALL_DIR/models/checkpoints"
                wget -q --show-progress -P "$INSTALL_DIR/models/checkpoints/" \
                    "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
                echo -e "${GREEN}✓ SDXL Base 1.0 downloaded.${NC}"
                ;;
            *)
                echo "Skipping model download."
                echo -e "You can download models later to: ${BLUE}$INSTALL_DIR/models/checkpoints/${NC}"
                ;;
        esac
        echo ""
        echo -e "After starting, access ComfyUI at: ${BLUE}http://localhost:8188${NC}"
        ;;
    office_inference)
        echo -e "${GREEN}Office Inference Stack (Ollama + Open WebUI)${NC}"
        echo "Note: You will be prompted to download models after the container launches."
        echo "      (Or use ./init.sh at any time)"
        ;;
    docker-base)
        echo "Base environment ready for Python development."
        echo "Edit files in '$INSTALL_DIR/src/' and rebuild."
        ;;
    *)
        echo "Stack ready. Edit files in '$INSTALL_DIR/src/' and rebuild."
        ;;
esac

echo -e "\n${YELLOW}[Step 5] Launch${NC}"
read -p "Would you like to build and start the container now? (Y/n): " START_NOW
if [[ "$START_NOW" != "n" && "$START_NOW" != "N" ]]; then
    echo -e "${BLUE}Building and starting container in background...${NC}"
    cd "$INSTALL_DIR"
    
    # Check for container name conflicts (since we use static names in some packs)
    # We try to get the container name from docker-compose.yml if possible, or just handle the error
    # Here we'll just attempt to stop and remove any existing container using the project's names
    # or conflicting names we know about (like puget_comfy_ui)
    docker compose down 2>/dev/null || true
    
    # Specifically check for the comfy_ui conflict the user saw
    if [ "$FLAVOR" == "comfy_ui" ]; then
        if docker ps -a --format '{{.Names}}' | grep -q "^puget_comfy_ui$"; then
            echo -e "${YELLOW}⚠ Conflict: A container named 'puget_comfy_ui' already exists.${NC}"
            read -p "  Would you like to remove the existing container to continue? (y/N): " REMOVE_CONFLICT
            if [[ "$REMOVE_CONFLICT" == "y" || "$REMOVE_CONFLICT" == "Y" ]]; then
                echo -e "${BLUE}Removing existing container 'puget_comfy_ui'...${NC}"
                docker rm -f puget_comfy_ui 2>/dev/null || true
            else
                echo -e "${RED}Error: Cannot launch because of name conflict.${NC}"
                echo "Please stop/remove the existing container or choose a different installation name."
                cd - > /dev/null
                exit 1
            fi
        fi
    fi

    docker compose up --build -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container started successfully!${NC}"
        
        # Show access URL based on flavor
        case $FLAVOR in
            comfy_ui)
                LOCAL_IP=$(hostname -I | awk '{print $1}')
                echo -e "\n${GREEN}Access ComfyUI at:${NC}"
                echo -e "  Local:   ${BLUE}http://localhost:8188${NC}"
                echo -e "  Network: ${BLUE}http://${LOCAL_IP}:8188${NC}"
                ;;
            office_inference)
                LOCAL_IP=$(hostname -I | awk '{print $1}')
                echo -e "\n${GREEN}Access Open WebUI at:${NC}"
                echo -e "  Local:   ${BLUE}http://localhost:3000${NC}"
                echo -e "  Network: ${BLUE}http://${LOCAL_IP}:3000${NC}"
                echo ""
                echo "Select a starter model to download:"
                echo "  1) Llama 3.2 (3B)   - Balanced, Fast, Low VRAM (Recommended)"
                echo "  2) DeepSeek R1 (7B) - State-of-the-art Reasoning"
                echo "  3) Qwen 2.5 (7B)    - Excellent for Coding & Math"
                echo "  4) Skip             - I'll download models later"
                echo ""
                read -p "Select a model [1-4]: " MODEL_SELECT
                
                MODEL_TAG=""
                case $MODEL_SELECT in
                    1) MODEL_TAG="llama3.2" ;;
                    2) MODEL_TAG="deepseek-r1" ;;
                    3) MODEL_TAG="qwen2.5" ;;
                    *) echo "Skipping model download." ;;
                esac

                if [[ -n "$MODEL_TAG" ]]; then
                     echo -e "${BLUE}Downloading $MODEL_TAG... (This may take a moment)${NC}"
                     docker compose exec inference ollama pull "$MODEL_TAG"
                     echo -e "${GREEN}✓ Model ready.${NC}"
                else
                     echo -e "Run ${BLUE}./init.sh${NC} later to download models."
                fi
                ;;
        esac
    else
        echo -e "${RED}Container failed to start. Check logs with: docker compose logs${NC}"
    fi
    cd - > /dev/null
fi

# Offer auto-start on boot
echo ""
read -p "Would you like this container to start automatically on system boot? (Y/n): " AUTO_START
if [[ "$AUTO_START" != "n" && "$AUTO_START" != "N" ]]; then
    # Ensure Docker service starts on boot
    sudo systemctl enable docker 2>/dev/null || true
    
    # The docker-compose.yml already has restart: unless-stopped
    # But we need the container to exist, so start it if not running
    cd "$INSTALL_DIR"
    if ! docker compose ps --quiet 2>/dev/null | grep -q .; then
        docker compose up -d
    fi
    cd - > /dev/null
    
    echo -e "${GREEN}✓ Auto-start configured.${NC}"
    echo "  Container will restart automatically after reboot."
    echo "  (Uses Docker's 'restart: unless-stopped' policy)"
fi

echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Useful commands:"
echo -e "  ${BLUE}cd $INSTALL_DIR${NC}              - Go to installation"
echo -e "  ${BLUE}docker compose logs -f${NC}      - View logs"
echo -e "  ${BLUE}docker compose restart${NC}      - Restart container"
echo -e "  ${BLUE}docker compose down${NC}         - Stop container"

