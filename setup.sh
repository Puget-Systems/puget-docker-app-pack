#!/bin/bash

# Puget Systems App Pack - One-Line Bootstrap Installer
# This script downloads the latest installer logic and runs it.

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/Puget-Systems/puget-docker-app-pack.git"
BRANCH="main"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Puget Systems Docker App Pack - Bootstrap Installer${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. Dependency Check
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: 'git' is not installed. Please install git and try again.${NC}"
    exit 1
fi

# 2. Setup Temporary Environment
TEMP_DIR=$(mktemp -d)
PROJECT_NAME="puget-docker-app-pack"

cleanup() {
    # echo -e "\n${BLUE}Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo -e "\n${BLUE}Fetching latest install scripts from GitHub...${NC}"

# 3. Clone Repository (Shallow clone for speed)
if git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/$PROJECT_NAME" &> /dev/null; then
    echo -e "${GREEN}Assets acquired.${NC}"
else
    echo -e "${RED}Error: Failed to download repository.${NC}"
    exit 1
fi

# 4. Handover to Main Installer
# We execute the installer from the temp directory, but we pass the CURRENT directory
# as context if needed, though the interactive script handles CWD.
INSTALLER_PATH="$TEMP_DIR/$PROJECT_NAME/install.sh"
chmod +x "$INSTALLER_PATH"

echo -e "${BLUE}Launching Installer...${NC}"
"$INSTALLER_PATH"

# Exit code of the installer will be returned by this script
exit $?
