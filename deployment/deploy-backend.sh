#!/bin/bash
#
# Backend (WOPI Server) Deployment Script
# Run this script on the Linux server to deploy the WOPI backend
#

set -e  # Exit on error

echo "========================================"
echo "WOPI Server Deployment Script"
echo "========================================"
echo ""

# Configuration
BACKEND_DIR="/opt/wopi-server"
SERVICE_NAME="wopi-server"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PYTHON_BIN="/usr/bin/python3"

# Detect script location and find repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_SOURCE="$REPO_ROOT/backend"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Install system dependencies
echo "Step 1: Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Step 2: Create backend directory
echo ""
echo "Step 2: Creating backend directory..."
mkdir -p "$BACKEND_DIR"
mkdir -p "$BACKEND_DIR/documents"

# Step 3: Copy files
echo ""
echo "Step 3: Copying backend files..."
echo "Source: $BACKEND_SOURCE"
echo ""

# Check if backend directory exists
if [ ! -d "$BACKEND_SOURCE" ]; then
    echo "ERROR: Backend source directory not found: $BACKEND_SOURCE"
    echo "Make sure you're running this from the Collabora-Test repository"
    exit 1
fi

# Check if files exist
if [ ! -f "$BACKEND_SOURCE/wopi_server.py" ]; then
    echo "ERROR: wopi_server.py not found in $BACKEND_SOURCE"
    exit 1
fi

if [ ! -f "$BACKEND_SOURCE/requirements.txt" ]; then
    echo "ERROR: requirements.txt not found in $BACKEND_SOURCE"
    exit 1
fi

# Copy files
cp "$BACKEND_SOURCE/wopi_server.py" "$BACKEND_DIR/"
cp "$BACKEND_SOURCE/requirements.txt" "$BACKEND_DIR/"

# Copy documents if they exist
if [ -d "$BACKEND_SOURCE/documents" ]; then
    cp -r "$BACKEND_SOURCE/documents/"* "$BACKEND_DIR/documents/"
    echo "✓ Documents copied successfully"
else
    echo "Warning: documents directory not found"
fi

# Step 4: Create virtual environment and install dependencies
echo ""
echo "Step 4: Setting up Python virtual environment..."
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# Step 5: Set proper permissions
echo ""
echo "Step 5: Setting permissions..."
chown -R www-data:www-data "$BACKEND_DIR"
chmod 755 "$BACKEND_DIR"
chmod 644 "$BACKEND_DIR/wopi_server.py"
chmod 755 "$BACKEND_DIR/documents"

# Step 6: Create systemd service
echo ""
echo "Step 6: Creating systemd service..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=WOPI Server for Collabora CODE
Documentation=https://wopi.readthedocs.io/
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/python $BACKEND_DIR/wopi_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BACKEND_DIR/documents

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Enable and start service
echo ""
echo "Step 7: Enabling and starting WOPI server service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# Step 8: Check status
echo ""
echo "Step 8: Checking service status..."
sleep 2
systemctl status "$SERVICE_NAME" --no-pager

# Step 9: Test endpoint
echo ""
echo "Step 9: Testing WOPI server..."
sleep 2
if curl -s http://localhost:5001/health > /dev/null; then
    echo "✓ WOPI server is responding on port 5001"
else
    echo "✗ WOPI server is not responding"
    echo "Check logs: journalctl -u $SERVICE_NAME -f"
fi

echo ""
echo "========================================"
echo "Backend Deployment Complete!"
echo "========================================"
echo ""
echo "Service status: systemctl status $SERVICE_NAME"
echo "View logs: journalctl -u $SERVICE_NAME -f"
echo "Restart: sudo systemctl restart $SERVICE_NAME"
echo "Stop: sudo systemctl stop $SERVICE_NAME"
echo ""
echo "WOPI Server URL: http://localhost:5001"
echo "Health check: curl http://localhost:5001/health"
echo ""
