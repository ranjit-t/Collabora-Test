#!/bin/bash
###############################################################################
# Update Frontend Configuration Script
# Updates API URLs in deployed frontend
###############################################################################

set -e

# Configuration
FRONTEND_DIR="/var/www/app-exp-frontend"
DOMAIN="https://app-exp.dev.lan"

echo "=========================================="
echo "Updating Frontend Configuration"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if frontend exists
if [ ! -f "$FRONTEND_DIR/app.js" ]; then
    echo "❌ Frontend not found at $FRONTEND_DIR"
    echo "   Deploy frontend first: sudo ./frontend_deployment.sh"
    exit 1
fi

# Get Collabora URL
echo "🔍 Detecting Collabora URL..."
COLLABORA_URL=$(curl -s http://localhost:9980/hosting/discovery 2>/dev/null | grep -oP 'urlsrc="[^"]*' | head -1 | cut -d'"' -f2 || echo "")

if [ -z "$COLLABORA_URL" ]; then
    echo "⚠️  Could not detect Collabora URL automatically"
    echo "   Using default: $DOMAIN/browser/e808afa229/cool.html"
    COLLABORA_URL="$DOMAIN/browser/e808afa229/cool.html"
else
    # Replace localhost with domain
    COLLABORA_URL=$(echo "$COLLABORA_URL" | sed "s|http://localhost:9980|$DOMAIN|g")
    echo "   ✓ Detected: $COLLABORA_URL"
fi

# Update app.js
echo ""
echo "📝 Updating configuration..."

sed -i.bak "s|apiBaseUrl: '.*'|apiBaseUrl: '$DOMAIN'|g" "$FRONTEND_DIR/app.js"
sed -i.bak "s|collaboraServer: '.*'|collaboraServer: '$COLLABORA_URL'|g" "$FRONTEND_DIR/app.js"

echo "   ✓ Configuration updated"

# Reload nginx
echo ""
echo "🔄 Reloading nginx..."
systemctl reload nginx

echo ""
echo "=========================================="
echo "✅ Configuration Updated!"
echo "=========================================="
echo ""
echo "📍 API Base URL: $DOMAIN"
echo "📍 Collabora URL: $COLLABORA_URL"
echo ""
echo "🌐 Test your app: $DOMAIN"
echo ""
