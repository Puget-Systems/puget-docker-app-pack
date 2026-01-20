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
        echo -e "${BLUE}Installing Docker...${NC}"
        sudo apt update && sudo apt install -y docker.io docker-compose-v2
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✓ Docker installed. You may need to log out and back in for group changes.${NC}"
    fi
else
    echo -e "${GREEN}✓ Docker found.${NC}"
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
echo -e "\nNext Steps:"
echo "  1. cd $INSTALL_DIR"
echo "  2. docker compose up --build"
echo "  3. Start developing in 'src/'"
