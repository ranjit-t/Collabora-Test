#!/bin/bash
###############################################################################
# Backend Deployment Script
# Deploys WOPI Server with all dependencies
###############################################################################

set -e

echo "=========================================="
echo "Backend (WOPI Server) Deployment"
echo "=========================================="
echo ""

# Configuration
BACKEND_DIR="/opt/wopi-server"
SERVICE_NAME="wopi-server"

# Detect repository location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_SOURCE="$REPO_ROOT/backend"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Install system dependencies
echo "📦 Installing system dependencies..."
apt-get update -qq
apt-get install -y python3 python3-pip python3-venv curl

# Step 2: Create backend directory
echo "📁 Creating backend directory..."
mkdir -p "$BACKEND_DIR/documents"

# Step 3: Copy files
echo "📋 Copying backend files..."
if [ ! -f "$BACKEND_SOURCE/wopi_server.py" ]; then
    echo "❌ ERROR: wopi_server.py not found!"
    exit 1
fi

cp "$BACKEND_SOURCE/wopi_server.py" "$BACKEND_DIR/"
cp "$BACKEND_SOURCE/requirements.txt" "$BACKEND_DIR/"

# Copy documents if they exist
if [ -d "$BACKEND_SOURCE/documents" ] && [ "$(ls -A $BACKEND_SOURCE/documents)" ]; then
    cp "$BACKEND_SOURCE/documents/"* "$BACKEND_DIR/documents/" 2>/dev/null || true
    echo "   ✓ Documents copied"
fi

# Step 4: Setup Python environment
echo "🐍 Setting up Python virtual environment..."
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
deactivate

# Step 5: Set permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data "$BACKEND_DIR"
chmod 755 "$BACKEND_DIR"
chmod 755 "$BACKEND_DIR/documents"

# Step 6: Create systemd service
echo "⚙️  Creating systemd service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=WOPI Server for Collabora CODE
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

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BACKEND_DIR/documents

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Start service
echo "🚀 Starting WOPI server..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# Wait for service to start
sleep 3

# Step 8: Verify
echo ""
echo "✅ Verifying deployment..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "   ✓ WOPI server is running"
else
    echo "   ❌ WOPI server failed to start"
    echo "   View logs: journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "   ✓ Health check passed"
else
    echo "   ⚠️  Health check failed (service might still be starting)"
fi

echo ""
echo "=========================================="
echo "✅ Backend Deployment Complete!"
echo "=========================================="
echo ""
echo "📍 WOPI Server: http://localhost:5001"
echo "📊 Status: sudo systemctl status $SERVICE_NAME"
echo "📜 Logs: sudo journalctl -u $SERVICE_NAME -f"
echo ""
