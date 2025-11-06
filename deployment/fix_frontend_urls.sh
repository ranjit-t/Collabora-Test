#!/bin/bash
###############################################################################
# Fix Frontend URLs Script
# Forcefully updates all URLs in deployed frontend
###############################################################################

set -e

# Configuration
FRONTEND_DIR="/var/www/app-exp-frontend"
DOMAIN="https://app-exp.dev.lan"

echo "=========================================="
echo "Fixing Frontend URLs"
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
    exit 1
fi

echo "📝 Updating app.js..."

# Backup original
cp "$FRONTEND_DIR/app.js" "$FRONTEND_DIR/app.js.backup.$(date +%s)"

# Replace ALL localhost references with domain
sed -i "s|http://localhost:5001|$DOMAIN|g" "$FRONTEND_DIR/app.js"
sed -i "s|http://localhost:9980|$DOMAIN|g" "$FRONTEND_DIR/app.js"
sed -i "s|https://localhost:5001|$DOMAIN|g" "$FRONTEND_DIR/app.js"
sed -i "s|https://localhost:9980|$DOMAIN|g" "$FRONTEND_DIR/app.js"

# Verify changes
echo ""
echo "✅ Verification:"
echo ""
grep -n "apiBaseUrl:" "$FRONTEND_DIR/app.js" || echo "apiBaseUrl not found"
grep -n "collaboraServer:" "$FRONTEND_DIR/app.js" || echo "collaboraServer not found"

echo ""
echo "🔄 Clearing browser cache recommended!"
echo "   Press Ctrl+Shift+R or Cmd+Shift+R to hard refresh"
echo ""
echo "=========================================="
echo "✅ URLs Updated!"
echo "=========================================="
echo ""
