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
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        echo -e "${GREEN}✓ NVIDIA Container Toolkit installed.${NC}"
    fi
else
    echo -e "${GREEN}✓ NVIDIA Container Toolkit found.${NC}"
fi

# Re-check after potential installs
if ! command -v docker &> /dev/null; then
    echo -e "\n${RED}Docker is still not available. Cannot continue.${NC}"
    echo "Please install Docker manually and run this installer again."
    exit 1
fi

# 1. Directory Setup
DEFAULT_DIR="my-puget-app"
echo -e "\n${YELLOW}[Step 1] Configuration${NC}"
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

# 2. Flavor Selection
echo -e "\n${YELLOW}[Step 2] Select Application Flavor${NC}"
echo "Different flavors are optimized for different use cases:"
echo "--------------------------------------------------------"

# Dynamically list packs
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

PS3="Select a flavor (enter number): "
select FLAVOR in "${OPTIONS[@]}"; do
    if [ -n "$FLAVOR" ]; then
        echo -e "Selected Flavor: ${GREEN}$FLAVOR${NC}"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

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
        echo ""
        echo "To download a starter model (SDXL, ~6GB):"
        echo -e "  ${GREEN}wget -P $INSTALL_DIR/models/checkpoints/ https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors${NC}"
        echo ""
        echo "Or for a lightweight test (SD 1.5, ~2GB):"
        echo -e "  ${GREEN}wget -P $INSTALL_DIR/models/checkpoints/ https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors${NC}"
        echo ""
        echo -e "After starting, access ComfyUI at: ${BLUE}http://localhost:8188${NC}"
        ;;
    office_inference)
        echo "Office Inference uses Ollama for local AI."
        echo ""
        echo "After starting, pull a model:"
        echo -e "  ${GREEN}docker exec -it puget_ollama ollama pull llama3.2${NC}"
        echo -e "  ${GREEN}docker exec -it puget_ollama ollama pull codellama${NC}"
        echo ""
        echo "AutoGen will connect to Ollama at http://ollama:11434"
        ;;
    docker-base)
        echo "Base environment ready for Python development."
        echo "Edit files in '$INSTALL_DIR/src/' and rebuild."
        ;;
    *)
        echo "Stack ready. Edit files in '$INSTALL_DIR/src/' and rebuild."
        ;;
esac

echo -e "\n${YELLOW}[Next Steps]${NC}"
echo "  1. cd $INSTALL_DIR"
echo -e "  2. ${GREEN}docker compose up --build${NC}"
echo "  3. Start developing in 'src/'"
