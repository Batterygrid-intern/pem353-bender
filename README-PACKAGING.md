# Building and Packaging pem353-bender on Raspberry Pi

This guide explains how to build and package the pem353-bender application natively on your Raspberry Pi and create a .deb package for easy installation.

## Prerequisites

- Raspberry Pi 4 running Raspberry Pi OS (32-bit or 64-bit)
- Internet connection for installing dependencies

## Quick Start

### 1. Install Dependencies

First, install all required dependencies:

```bash
chmod +x install-deps.sh
sudo ./install-deps.sh
```

This will install:
- Build tools (gcc, g++, cmake, make)
- libmodbus-dev (Modbus library)
- libspdlog-dev (logging library)
- dpkg-dev (for creating .deb packages)

### 2. Build the Application

Build the application in release mode:

```bash
chmod +x build.sh
./build.sh
```

The compiled binary will be placed in `bin/pem353`.

### 3. Create .deb Package

Package the application as a .deb file:

```bash
chmod +x package-deb.sh
./package-deb.sh
```

This creates a .deb package file: `pem353-bender_1.0.0_armhf.deb` (or `arm64` for 64-bit OS).

### 4. Install the Package

Install the .deb package:

```bash
sudo dpkg -i pem353-bender_1.0.0_*.deb
```

If you encounter dependency errors:

```bash
sudo apt-get install -f
```

## Managing the Service

After installation, the pem353-bender service is automatically enabled but not started.

### Configure the Service

Edit the configuration file before starting:

```bash
sudo nano /etc/pem353/pemConfigs.json
```

### Start the Service

```bash
sudo systemctl start pem353-bender
```

### Check Service Status

```bash
sudo systemctl status pem353-bender
```

### View Logs

```bash
# Follow live logs
sudo journalctl -u pem353-bender -f

# View recent logs
sudo journalctl -u pem353-bender -n 100
```

### Stop the Service

```bash
sudo systemctl stop pem353-bender
```

### Restart the Service

```bash
sudo systemctl restart pem353-bender
```

### Disable Auto-start

```bash
sudo systemctl disable pem353-bender
```

### Enable Auto-start

```bash
sudo systemctl enable pem353-bender
```

## Uninstalling

To remove the package:

```bash
sudo dpkg -r pem353-bender
```

Or to remove including configuration files:

```bash
sudo dpkg -P pem353-bender
```

## Package Contents

The .deb package installs:

- **Binary**: `/usr/local/bin/pem353`
- **Configuration**: `/etc/pem353/pemConfigs.json`
- **Systemd service**: `/lib/systemd/system/pem353-bender.service`
- **Log directory**: `/var/log/pem353/`

## Customization

### Changing Package Version

Edit the `VERSION` variable in `package-deb.sh`:

```bash
VERSION="1.0.1"
```

### Changing Maintainer Information

Edit the `MAINTAINER` variable in `package-deb.sh`:

```bash
MAINTAINER="Your Name <your.email@example.com>"
```

### Modifying Service Configuration

The systemd service file is created during packaging. To modify it, edit the service template in `package-deb.sh` before running the script.

Key service settings:
- **User**: Currently runs as `root` (needed for serial port access)
- **WorkingDirectory**: `/etc/pem353`
- **Restart**: Automatically restarts on failure
- **RestartSec**: Waits 10 seconds before restarting

## Troubleshooting

### Build Fails

1. Ensure all dependencies are installed:
   ```bash
   sudo ./install-deps.sh
   ```

2. Clean the build directory:
   ```bash
   rm -rf build-release bin
   ./build.sh
   ```

### Service Won't Start

1. Check the logs:
   ```bash
   sudo journalctl -u pem353-bender -n 50
   ```

2. Verify serial port permissions:
   ```bash
   ls -l /dev/ttyS0
   # Should show: crw-rw---- 1 root dialout
   ```

3. Check configuration file:
   ```bash
   cat /etc/pem353/pemConfigs.json
   ```

### Package Installation Fails

If you get dependency errors:

```bash
sudo apt-get update
sudo apt-get install -f
```

### Serial Port Access Denied

The service runs as root to access `/dev/ttyS0`. If you want to run as a different user, add them to the `dialout` group:

```bash
sudo usermod -a -G dialout pem353user
```

Then modify the service file to use that user.

## Development Workflow

For development on the Raspberry Pi:

1. Make code changes
2. Build: `./build.sh`
3. Test manually: `./bin/pem353`
4. When ready to deploy: `./package-deb.sh`
5. Install: `sudo dpkg -i pem353-bender_1.0.0_*.deb`

## Distribution

To distribute your application:

1. Copy the .deb file to target Raspberry Pi devices
2. Install with: `sudo dpkg -i pem353-bender_1.0.0_*.deb`
3. Configure: Edit `/etc/pem353/pemConfigs.json`
4. Start: `sudo systemctl start pem353-bender`
