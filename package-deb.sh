#!/bin/bash
# Package pem353-bender as a .deb file
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Package information
PACKAGE_NAME="pem353-bender"
VERSION="1.0.0"
ARCH="arm64"  # Change to arm64 if using 64-bit OS
MAINTAINER="Your Name <luddenorin@gmail.com>"
DESCRIPTION="PEM353 Bender Modbus RTU to TCP/IP and MQTT gateway"

# Detect architecture
if [ "$(uname -m)" = "aarch64" ]; then
    ARCH="arm64"
fi

echo "========================================"
echo "Packaging $PACKAGE_NAME v$VERSION"
echo "Architecture: $ARCH"
echo "========================================"

# Check if binary exists
if [ ! -f "bin/pem353" ]; then
    echo -e "${RED}Error: Binary not found at bin/pem353${NC}"
    echo "Please run ./build.sh first"
    exit 1
fi

# Create package directory structure
PKG_DIR="$SCRIPT_DIR/package"
DEB_DIR="$PKG_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}"

echo -e "${YELLOW}Creating package directory structure...${NC}"
rm -rf "$PKG_DIR"
mkdir -p "$DEB_DIR"

# Create directory structure
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/etc/pem353"
mkdir -p "$DEB_DIR/lib/systemd/system"
mkdir -p "$DEB_DIR/var/log/pem353"

# Copy binary
echo -e "${YELLOW}Copying binary...${NC}"
cp bin/pem353 "$DEB_DIR/usr/local/bin/"
chmod +x "$DEB_DIR/usr/local/bin/pem353"

# Copy config file if it exists
if [ -f "configs/pemConfigs.json" ]; then
    echo -e "${YELLOW}Copying config file...${NC}"
    cp configs/pemConfigs.json "$DEB_DIR/etc/pem353/"
fi

# Create systemd service file
echo -e "${YELLOW}Creating systemd service file...${NC}"
cat > "$DEB_DIR/lib/systemd/system/pem353-bender.service" << 'EOF'
[Unit]
Description=PEM353 Bender Modbus Gateway Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/pem353
ExecStart=/usr/local/bin/pem353
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Create control file
echo -e "${YELLOW}Creating control file...${NC}"
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: misc
Priority: optional
Architecture: $ARCH
Depends: libmodbus5, libspdlog1
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 This service reads data from PEM353 Bender device via Modbus RTU (RS-485)
 and makes it available via Modbus TCP/IP and publishes to MQTT broker.
EOF

# Create postinst script (runs after installation)
echo -e "${YELLOW}Creating post-installation script...${NC}"
cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Reload systemd
systemctl daemon-reload

# Enable service (but don't start yet - let user configure first)
systemctl enable pem353-bender.service

echo "=========================================="
echo "pem353-bender installed successfully!"
echo "=========================================="
echo "Configuration file: /etc/pem353/pemConfigs.json"
echo ""
echo "To start the service:"
echo "  sudo systemctl start pem353-bender"
echo ""
echo "To check status:"
echo "  sudo systemctl status pem353-bender"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u pem353-bender -f"
echo "=========================================="

exit 0
EOF
chmod +x "$DEB_DIR/DEBIAN/postinst"

# Create prerm script (runs before removal)
echo -e "${YELLOW}Creating pre-removal script...${NC}"
cat > "$DEB_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

# Stop service if running
if systemctl is-active --quiet pem353-bender.service; then
    systemctl stop pem353-bender.service
fi

# Disable service
systemctl disable pem353-bender.service || true

exit 0
EOF
chmod +x "$DEB_DIR/DEBIAN/prerm"

# Create postrm script (runs after removal)
echo -e "${YELLOW}Creating post-removal script...${NC}"
cat > "$DEB_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e

# Reload systemd
systemctl daemon-reload

echo "pem353-bender has been removed"
echo "Configuration files remain in /etc/pem353"
echo "Log files remain in /var/log/pem353"

exit 0
EOF
chmod +x "$DEB_DIR/DEBIAN/postrm"

# Build the .deb package
echo -e "${YELLOW}Building .deb package...${NC}"
dpkg-deb --build "$DEB_DIR"

# Move the .deb file to a more accessible location
mv "$PKG_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" "$SCRIPT_DIR/"

# Clean up
rm -rf "$PKG_DIR"

echo -e "${GREEN}========================================"
echo "Package created successfully!"
echo "File: $SCRIPT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "========================================${NC}"
echo ""
echo "To install:"
echo "  sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo ""
echo "If you get dependency errors, run:"
echo "  sudo apt-get install -f"
