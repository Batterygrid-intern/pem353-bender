#!/bin/bash
# Build script for pem353-bender on Raspberry Pi
set -e

echo "========================================"
echo "Building pem353-bender"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create build directory
BUILD_DIR="build-release"
echo -e "${YELLOW}Creating build directory: $BUILD_DIR${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"
MISSING_DEPS=""

# Check for cmake
if ! command -v cmake &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS cmake"
fi

# Check for libmodbus
if ! pkg-config --exists libmodbus; then
    MISSING_DEPS="$MISSING_DEPS libmodbus-dev"
fi

# Check for spdlog
if ! pkg-config --exists spdlog; then
    MISSING_DEPS="$MISSING_DEPS libspdlog-dev"
fi

if [ ! -z "$MISSING_DEPS" ]; then
    echo -e "${RED}Missing dependencies:$MISSING_DEPS${NC}"
    echo -e "${YELLOW}Install them with:${NC}"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y build-essential cmake$MISSING_DEPS"
    exit 1
fi

echo -e "${GREEN}All dependencies found!${NC}"

# Run CMake
echo -e "${YELLOW}Running CMake...${NC}"
cmake -DCMAKE_BUILD_TYPE=Release ..

# Build
echo -e "${YELLOW}Building...${NC}"
make -j$(nproc)

echo -e "${GREEN}========================================"
echo "Build completed successfully!"
echo "Executable: $SCRIPT_DIR/bin/pem353"
echo "========================================${NC}"
