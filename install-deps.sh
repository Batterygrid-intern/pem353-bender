#!/bin/bash
# Install dependencies for building pem353-bender on Raspberry Pi
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Installing dependencies for pem353-bender"
echo "========================================"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Updating package list...${NC}"
apt-get update

echo -e "${YELLOW}Installing build tools...${NC}"
apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    dpkg-dev

echo -e "${YELLOW}Installing required libraries...${NC}"
apt-get install -y \
    libmodbus-dev \
    libspdlog-dev

echo -e "${GREEN}========================================"
echo "All dependencies installed successfully!"
echo "========================================${NC}"
echo ""
echo "You can now build the project with:"
echo "  ./build.sh"
