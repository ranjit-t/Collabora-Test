#!/bin/bash
###############################################################################
# Stop All Services Script
# Stops Collabora, WOPI Server, and Nginx
###############################################################################

set -e

echo "=========================================="
echo "Stopping All Services"
echo "=========================================="
echo ""

# Stop WOPI Server
echo "⏹️  Stopping WOPI Server..."
sudo systemctl stop wopi-server 2>/dev/null || echo "   WOPI server not running"

# Stop Nginx
echo "⏹️  Stopping Nginx..."
sudo systemctl stop nginx 2>/dev/null || echo "   Nginx not running"

# Stop Collabora Docker container
echo "⏹️  Stopping Collabora..."
sudo docker stop collabora 2>/dev/null || echo "   Collabora not running"

echo ""
echo "✅ All services stopped!"
echo ""

# Show status
echo "Service Status:"
echo "----------------------------------------"
systemctl is-active wopi-server 2>/dev/null || echo "WOPI Server: stopped"
systemctl is-active nginx 2>/dev/null || echo "Nginx: stopped"
sudo docker ps | grep collabora >/dev/null 2>&1 && echo "Collabora: running" || echo "Collabora: stopped"
echo ""
