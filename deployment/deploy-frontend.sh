#!/bin/bash
#
# Frontend Deployment Script
# Run this script on the Linux server to deploy the frontend application
#

set -e  # Exit on error

echo "========================================"
echo "Frontend Deployment Script"
echo "========================================"
echo ""

# Configuration
FRONTEND_DIR="/var/www/app-exp-frontend"
NGINX_AVAILABLE="/etc/nginx/sites-available/app-exp"
NGINX_ENABLED="/etc/nginx/sites-enabled/app-exp"

# Detect script location and find repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_SOURCE="$REPO_ROOT/frontend"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Install nginx if not installed
echo "Step 1: Checking nginx installation..."
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    apt-get update
    apt-get install -y nginx
else
    echo "✓ nginx is already installed"
fi

# Step 2: Create frontend directory
echo ""
echo "Step 2: Creating frontend directory..."
mkdir -p "$FRONTEND_DIR"

# Step 3: Copy frontend files
echo ""
echo "Step 3: Copying frontend files..."
echo "Source: $FRONTEND_SOURCE"
echo ""

# Check if frontend directory exists
if [ ! -d "$FRONTEND_SOURCE" ]; then
    echo "ERROR: Frontend source directory not found: $FRONTEND_SOURCE"
    echo "Make sure you're running this from the Collabora-Test repository"
    exit 1
fi

# Check if files exist
if [ ! -f "$FRONTEND_SOURCE/index.html" ]; then
    echo "ERROR: index.html not found in $FRONTEND_SOURCE"
    exit 1
fi

if [ ! -f "$FRONTEND_SOURCE/app.js" ]; then
    echo "ERROR: app.js not found in $FRONTEND_SOURCE"
    exit 1
fi

if [ ! -f "$FRONTEND_SOURCE/styles.css" ]; then
    echo "ERROR: styles.css not found in $FRONTEND_SOURCE"
    exit 1
fi

# Copy files
cp "$FRONTEND_SOURCE/index.html" "$FRONTEND_DIR/"
cp "$FRONTEND_SOURCE/app.js" "$FRONTEND_DIR/"
cp "$FRONTEND_SOURCE/styles.css" "$FRONTEND_DIR/"

echo "✓ Frontend files copied successfully"

# Step 4: Set proper permissions
echo ""
echo "Step 4: Setting permissions..."
chown -R www-data:www-data "$FRONTEND_DIR"
chmod 755 "$FRONTEND_DIR"
chmod 644 "$FRONTEND_DIR"/*

# Step 5: Update nginx configuration
echo ""
echo "Step 5: Checking nginx configuration..."
if [ -f "$SCRIPT_DIR/nginx-app-exp.conf" ]; then
    echo "Copying nginx configuration..."
    cp "$SCRIPT_DIR/nginx-app-exp.conf" "$NGINX_AVAILABLE"

    # Create symbolic link if it doesn't exist
    if [ ! -L "$NGINX_ENABLED" ]; then
        ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
        echo "Created nginx site link"
    fi

    # Remove default site if it exists
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        echo "Removing default nginx site..."
        rm -f "/etc/nginx/sites-enabled/default"
    fi
else
    echo "Warning: nginx-app-exp.conf not found. Skipping nginx configuration update."
    echo "You'll need to configure nginx manually."
fi

# Step 6: Test nginx configuration
echo ""
echo "Step 6: Testing nginx configuration..."
if nginx -t; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration has errors"
    echo "Please fix the errors before proceeding"
    exit 1
fi

# Step 7: Reload nginx
echo ""
echo "Step 7: Reloading nginx..."
systemctl reload nginx

# Step 8: Enable nginx to start on boot
echo ""
echo "Step 8: Enabling nginx service..."
systemctl enable nginx

# Step 9: Check nginx status
echo ""
echo "Step 9: Checking nginx status..."
systemctl status nginx --no-pager || true

echo ""
echo "========================================"
echo "Frontend Deployment Complete!"
echo "========================================"
echo ""
echo "Frontend location: $FRONTEND_DIR"
echo "Nginx config: $NGINX_AVAILABLE"
echo ""
echo "Commands:"
echo "  Test config: sudo nginx -t"
echo "  Reload nginx: sudo systemctl reload nginx"
echo "  Restart nginx: sudo systemctl restart nginx"
echo "  View logs: sudo tail -f /var/log/nginx/app-exp-error.log"
echo ""
echo "Access your application at: https://app-exp.dev.lan"
echo ""
