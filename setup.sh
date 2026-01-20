#!/bin/sh

# Puget Systems App Pack - One-Line Bootstrap Installer
# This script downloads the latest installer logic and runs it.
# Dependencies: curl OR wget (no git required)

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/Puget-Systems/puget-docker-app-pack/archive/refs/heads/main.tar.gz"
PROJECT_NAME="puget-docker-app-pack"

echo "${BLUE}============================================================${NC}"
echo "${BLUE}   Puget Systems Docker App Pack - Bootstrap Installer${NC}"
echo "${BLUE}============================================================${NC}"

# 1. Setup Temporary Environment
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo ""
echo "${BLUE}Fetching latest install scripts...${NC}"

# 2. Download and Extract (curl or wget)
ARCHIVE_PATH="$TEMP_DIR/pack.tar.gz"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_URL" -o "$ARCHIVE_PATH"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$REPO_URL" -O "$ARCHIVE_PATH"
else
    echo "${RED}Error: Neither 'curl' nor 'wget' found. Please install one.${NC}"
    exit 1
fi

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "${RED}Error: Failed to download repository archive.${NC}"
    exit 1
fi

# 3. Extract Archive
tar -xzf "$ARCHIVE_PATH" -C "$TEMP_DIR"
echo "${GREEN}Assets acquired.${NC}"

# 4. Handover to Main Installer
# GitHub archives extract to <repo>-<branch>/ directory
INSTALLER_PATH="$TEMP_DIR/${PROJECT_NAME}-main/install.sh"
chmod +x "$INSTALLER_PATH"

echo "${BLUE}Launching Installer...${NC}"
"$INSTALLER_PATH"

exit $?
