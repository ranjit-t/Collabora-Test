#!/bin/bash
###############################################################################
# Frontend Deployment Script
# Deploys frontend files and configures Nginx
###############################################################################

set -e

echo "=========================================="
echo "Frontend Deployment"
echo "=========================================="
echo ""

# Configuration
FRONTEND_DIR="/var/www/app-exp-frontend"
NGINX_AVAILABLE="/etc/nginx/sites-available/app-exp"
NGINX_ENABLED="/etc/nginx/sites-enabled/app-exp"

# Detect repository location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_SOURCE="$REPO_ROOT/frontend"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Install nginx
echo "📦 Checking nginx installation..."
if ! command -v nginx &> /dev/null; then
    apt-get update -qq
    apt-get install -y nginx
    echo "   ✓ Nginx installed"
else
    echo "   ✓ Nginx already installed"
fi

# Step 2: Create frontend directory
echo "📁 Creating frontend directory..."
mkdir -p "$FRONTEND_DIR"

# Step 3: Copy frontend files
echo "📋 Copying frontend files..."
if [ ! -f "$FRONTEND_SOURCE/index.html" ]; then
    echo "❌ ERROR: index.html not found!"
    exit 1
fi

cp "$FRONTEND_SOURCE/index.html" "$FRONTEND_DIR/"
cp "$FRONTEND_SOURCE/app.js" "$FRONTEND_DIR/"
cp "$FRONTEND_SOURCE/styles.css" "$FRONTEND_DIR/"
echo "   ✓ Files copied"

# Step 4: Set permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data "$FRONTEND_DIR"
chmod 755 "$FRONTEND_DIR"
chmod 644 "$FRONTEND_DIR"/*

# Step 5: Configure nginx
echo "⚙️  Configuring nginx..."
if [ -f "$SCRIPT_DIR/nginx-app-exp.conf" ]; then
    cp "$SCRIPT_DIR/nginx-app-exp.conf" "$NGINX_AVAILABLE"

    # Create symbolic link
    if [ ! -L "$NGINX_ENABLED" ]; then
        ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
    fi

    # Remove default site
    rm -f "/etc/nginx/sites-enabled/default"

    echo "   ✓ Nginx configured"
else
    echo "   ⚠️  nginx-app-exp.conf not found - configure manually"
fi

# Step 6: Test and reload nginx
echo "🧪 Testing nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "   ✓ Configuration valid"

    echo "🔄 Reloading nginx..."
    systemctl enable nginx
    systemctl reload nginx
    echo "   ✓ Nginx reloaded"
else
    echo "   ❌ Nginx configuration has errors"
    nginx -t
    exit 1
fi

# Step 7: Update frontend configuration
echo ""
echo "⚙️  Updating frontend configuration..."
bash "$SCRIPT_DIR/update_frontend_config.sh" || echo "   ⚠️  Config update failed (run manually later)"

# Step 8: Verify
echo ""
echo "✅ Verifying deployment..."
if systemctl is-active --quiet nginx; then
    echo "   ✓ Nginx is running"
else
    echo "   ❌ Nginx is not running"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Frontend Deployment Complete!"
echo "=========================================="
echo ""
echo "📍 Application: https://app-exp.dev.lan"
echo "📊 Status: sudo systemctl status nginx"
echo "📜 Logs: sudo tail -f /var/log/nginx/app-exp-error.log"
echo ""
