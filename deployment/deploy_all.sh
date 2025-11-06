#!/bin/bash
###############################################################################
# Complete Deployment Script
# Deploys Collabora, Backend, and Frontend all at once
###############################################################################

set -e

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Document Management System Deployment ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

echo "This will deploy:"
echo "  1️⃣  Collabora CODE (Docker)"
echo "  2️⃣  Backend (WOPI Server)"
echo "  3️⃣  Frontend (Web Interface)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "=========================================="
echo "STEP 1: Deploying Collabora CODE"
echo "=========================================="
echo ""
bash "$SCRIPT_DIR/setup-collabora.sh"

echo ""
echo "=========================================="
echo "STEP 2: Deploying Backend (WOPI Server)"
echo "=========================================="
echo ""
bash "$SCRIPT_DIR/backend_deployment.sh"

echo ""
echo "=========================================="
echo "STEP 3: Deploying Frontend"
echo "=========================================="
echo ""
bash "$SCRIPT_DIR/frontend_deployment.sh"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║     ✅ DEPLOYMENT COMPLETE! ✅         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "📍 Access your application:"
echo "   https://app-exp.dev.lan"
echo ""
echo "🔧 Service Management:"
echo "   Status:  sudo systemctl status wopi-server nginx"
echo "   Restart: sudo systemctl restart wopi-server nginx"
echo "   Logs:    sudo journalctl -u wopi-server -f"
echo ""
echo "🐳 Collabora:"
echo "   Status:  sudo docker ps | grep collabora"
echo "   Restart: sudo docker restart collabora"
echo "   Logs:    sudo docker logs -f collabora"
echo ""
echo "⚠️  IMPORTANT: Update Collabora URL in frontend/app.js"
echo "   Run: curl http://localhost:9980/hosting/discovery | grep urlsrc | head -1"
echo "   Then edit: /var/www/app-exp-frontend/app.js (line 11)"
echo ""
