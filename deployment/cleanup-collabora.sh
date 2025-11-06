#!/bin/bash
#
# Collabora Cleanup Script
# Use this if you get "port already allocated" error
#

echo "========================================"
echo "Collabora Cleanup Script"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Stop all collabora containers
echo "Step 1: Stopping all Collabora containers..."
docker ps -a | grep collabora | awk '{print $1}' | xargs -r docker stop 2>/dev/null
echo "✓ Containers stopped"

# Remove all collabora containers
echo ""
echo "Step 2: Removing all Collabora containers..."
docker ps -a | grep collabora | awk '{print $1}' | xargs -r docker rm 2>/dev/null
echo "✓ Containers removed"

# Kill processes on port 9980
echo ""
echo "Step 3: Cleaning up port 9980..."
if lsof -Pi :9980 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Killing processes on port 9980..."
    fuser -k 9980/tcp 2>/dev/null || true
    sleep 2
    echo "✓ Port 9980 cleaned"
else
    echo "✓ Port 9980 is already free"
fi

# Verify port is free
echo ""
echo "Step 4: Verifying port 9980 is free..."
if lsof -Pi :9980 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "✗ Port 9980 is still in use!"
    echo "Processes using port 9980:"
    lsof -Pi :9980 -sTCP:LISTEN
    echo ""
    echo "Try: sudo systemctl restart docker"
    exit 1
else
    echo "✓ Port 9980 is free"
fi

echo ""
echo "========================================"
echo "Cleanup Complete!"
echo "========================================"
echo ""
echo "You can now run: sudo ./setup-collabora.sh"
echo ""
