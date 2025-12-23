#!/usr/bin/env bash
set -euo pipefail

echo "==========================================="
echo "Cross-Compilation Setup for PEM353"
echo "==========================================="
echo ""

# Detect the OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
else
    echo "ERROR: Cannot detect OS" >&2
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Install toolchains
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    echo "[1/3] Installing ARM cross-compilation toolchains..."
    sudo apt-get update
    sudo apt-get install -y \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        crossbuild-essential-armhf \
        crossbuild-essential-arm64 \
        qemu-user-static \
        dpkg-dev

    echo ""
    echo "[2/3] Installing ARM dependencies..."

    # Add ARM architectures for multi-arch support
    sudo dpkg --add-architecture armhf
    sudo dpkg --add-architecture arm64
    sudo apt-get update

    # Install ARM versions of dependencies
    # Note: You may need to manually build libmodbus and spdlog for ARM
    echo "  ⚠ Note: You'll need to cross-compile libmodbus and spdlog"
    echo "    Or use a sysroot from your target device"
fi

echo ""
echo "[3/3] Verifying installation..."
echo ""


# Check ARM 64-bit toolchain
if command -v aarch64-linux-gnu-gcc &>/dev/null; then
    echo "✓ ARM 64-bit toolchain:"
    aarch64-linux-gnu-gcc --version | head -n1
else
    echo "✗ ARM 64-bit toolchain NOT found"
fi

echo ""
echo "==========================================="
echo "Setup complete!"
echo "==========================================="
echo ""
echo "Next steps:"
echo "  1. Set up a sysroot with your dependencies (libmodbus, spdlog)"
echo "  2. Build for ARM32: ./scripts/build_cross.sh armhf"
echo "  3. Build for ARM64: ./scripts/build_cross.sh arm64"
echo ""
echo "For sysroot setup, see: scripts/setup_sysroot.sh"