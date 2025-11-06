#!/bin/bash
#
# Collabora CODE Docker Setup Script
# Run this script on the Linux server to setup Collabora CODE
#

set -e  # Exit on error

echo "========================================"
echo "Collabora CODE Setup Script"
echo "========================================"
echo ""

# Configuration
CONTAINER_NAME="collabora"
IMAGE_NAME="collabora/code"
COLLABORA_PORT="9980"
DOMAIN="app-exp\\.dev\\.lan"  # Double backslash for Docker env
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="SecurePassword123"  # CHANGE THIS!

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Install Docker if not installed
echo "Step 1: Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
else
    echo "✓ Docker is already installed"
fi

# Step 2: Stop and remove existing container if it exists
echo ""
echo "Step 2: Removing existing Collabora container (if any)..."
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    echo "✓ Existing container removed"
else
    echo "No existing container found"
fi

# Force kill any process using port 9980
echo ""
echo "Checking if port 9980 is in use..."
if lsof -Pi :9980 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Port 9980 is in use. Cleaning up..."
    # Kill any docker-proxy processes on port 9980
    fuser -k 9980/tcp 2>/dev/null || true
    sleep 2
    echo "✓ Port 9980 cleaned up"
else
    echo "✓ Port 9980 is available"
fi

# Step 3: Pull latest Collabora CODE image
echo ""
echo "Step 3: Pulling Collabora CODE Docker image..."
echo "This may take a few minutes..."
docker pull "$IMAGE_NAME"

# Step 4: Start Collabora CODE container
echo ""
echo "Step 4: Starting Collabora CODE container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart always \
  -p "$COLLABORA_PORT:9980" \
  -e "domain=$DOMAIN" \
  -e "username=$ADMIN_USERNAME" \
  -e "password=$ADMIN_PASSWORD" \
  -e "extra_params=--o:ssl.enable=false --o:ssl.termination=true --o:net.frame_ancestors=* --o:logging.level=warning" \
  "$IMAGE_NAME"

echo "✓ Collabora CODE container started"

# Step 5: Wait for container to start
echo ""
echo "Step 5: Waiting for Collabora to start..."
echo "This may take 30-60 seconds..."
sleep 10

# Wait for Collabora to be ready (max 60 seconds)
COUNTER=0
MAX_ATTEMPTS=12
until curl -s http://localhost:$COLLABORA_PORT > /dev/null 2>&1; do
    sleep 5
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
        echo "Warning: Collabora may not be ready yet"
        break
    fi
    echo "Still waiting... ($((COUNTER * 5))s)"
done

# Step 6: Check container status
echo ""
echo "Step 6: Checking container status..."
docker ps | grep "$CONTAINER_NAME" || echo "Warning: Container may not be running"

# Step 7: Show container logs
echo ""
echo "Step 7: Recent container logs:"
echo "----------------------------------------"
docker logs --tail 20 "$CONTAINER_NAME" 2>&1 || true
echo "----------------------------------------"

# Step 8: Test discovery endpoint
echo ""
echo "Step 8: Testing discovery endpoint..."
sleep 5
if curl -s http://localhost:$COLLABORA_PORT/hosting/discovery > /dev/null; then
    echo "✓ Discovery endpoint is accessible"
else
    echo "✗ Discovery endpoint is not accessible yet"
    echo "Container may still be starting up"
fi

# Step 9: Display connection info
echo ""
echo "========================================"
echo "Collabora CODE Setup Complete!"
echo "========================================"
echo ""
echo "Container name: $CONTAINER_NAME"
echo "Port: $COLLABORA_PORT"
echo "Domain: $DOMAIN"
echo "Admin username: $ADMIN_USERNAME"
echo "Admin password: $ADMIN_PASSWORD"
echo ""
echo "Commands:"
echo "  View logs: docker logs -f $CONTAINER_NAME"
echo "  Stop: docker stop $CONTAINER_NAME"
echo "  Start: docker start $CONTAINER_NAME"
echo "  Restart: docker restart $CONTAINER_NAME"
echo "  Remove: docker rm -f $CONTAINER_NAME"
echo ""
echo "Endpoints (internal):"
echo "  Discovery: http://localhost:$COLLABORA_PORT/hosting/discovery"
echo "  Admin: http://localhost:$COLLABORA_PORT/browser/dist/admin/admin.html"
echo ""
echo "External access (via nginx):"
echo "  Admin: https://app-exp.dev.lan/browser/dist/admin/admin.html"
echo ""
echo "To get the editor URL for your application:"
echo "  curl -s http://localhost:$COLLABORA_PORT/hosting/discovery | grep urlsrc"
echo ""
echo "IMPORTANT: Update frontend/app.js with the correct editor URL"
echo "after running the discovery command above."
echo ""

# Step 10: Optional - Get editor URL
echo "Attempting to get editor URL..."
EDITOR_URL=$(curl -s http://localhost:$COLLABORA_PORT/hosting/discovery 2>/dev/null | grep -oP 'urlsrc="https://app-exp\.dev\.lan\K[^"]*' | head -1 || echo "")
if [ -n "$EDITOR_URL" ]; then
    echo ""
    echo "Editor URL: https://app-exp.dev.lan$EDITOR_URL"
    echo ""
    echo "Update this in frontend/app.js CONFIG.collaboraServer"
fi
