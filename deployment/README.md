# Deployment Scripts

This directory contains all deployment scripts for the Document Management System.

## 🚀 Quick Deployment

**Deploy everything at once:**
```bash
sudo ./deploy_all.sh
```

## 📝 Available Scripts

### Main Deployment Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `deploy_all.sh` | **Deploy everything** (Collabora + Backend + Frontend) | `sudo ./deploy_all.sh` |
| `backend_deployment.sh` | Deploy WOPI server only | `sudo ./backend_deployment.sh` |
| `frontend_deployment.sh` | Deploy web interface only | `sudo ./frontend_deployment.sh` |
| `setup-collabora.sh` | Deploy Collabora CODE only | `sudo ./setup-collabora.sh` |

### Utility Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `stop_services.sh` | Stop all services (Collabora, Backend, Frontend) | `sudo ./stop_services.sh` |
| `cleanup-collabora.sh` | Clean up Collabora Docker containers and ports | `sudo ./cleanup-collabora.sh` |
| `update_frontend_config.sh` | Update frontend API URLs (automatic in deployment) | `sudo ./update_frontend_config.sh` |
| `fix_frontend_urls.sh` | Force replace all localhost URLs with domain | `sudo ./fix_frontend_urls.sh` |

## 📋 Deployment Order

If deploying step by step:

1. **Collabora CODE** (Docker container)
   ```bash
   sudo ./setup-collabora.sh
   ```

2. **Backend** (WOPI Server)
   ```bash
   sudo ./backend_deployment.sh
   ```

3. **Frontend** (Web Interface + Nginx)
   ```bash
   sudo ./frontend_deployment.sh
   ```

## 🔄 Common Workflows

### First Time Deployment
```bash
cd ~/Collabora-Test/deployment
chmod +x *.sh
sudo ./deploy_all.sh
```

### Update After Git Pull
```bash
cd ~/Collabora-Test
git pull origin main
sudo ./deployment/stop_services.sh
cd deployment
sudo ./deploy_all.sh
```

### Redeploy Frontend Only
```bash
cd ~/Collabora-Test/deployment
sudo ./frontend_deployment.sh
```

### Redeploy Backend Only
```bash
cd ~/Collabora-Test/deployment
sudo ./backend_deployment.sh
```

### Fix Collabora Port Issues
```bash
cd ~/Collabora-Test/deployment
sudo ./cleanup-collabora.sh
sudo ./setup-collabora.sh
```

### Stop Everything
```bash
cd ~/Collabora-Test/deployment
sudo ./stop_services.sh
```

## ✅ What Each Script Does

### `deploy_all.sh`
- Runs all deployment scripts in order
- Deploys Collabora, Backend, and Frontend
- Shows final status and instructions

### `backend_deployment.sh`
- Installs Python dependencies
- Creates `/opt/wopi-server/` directory
- Copies backend files
- Sets up Python virtual environment
- Creates systemd service
- Starts WOPI server on port 5001

### `frontend_deployment.sh`
- Installs Nginx if needed
- Creates `/var/www/app-exp-frontend/` directory
- Copies HTML, CSS, JS files
- Configures Nginx reverse proxy
- Automatically updates API URLs (calls update_frontend_config.sh)
- Reloads Nginx

### `setup-collabora.sh`
- Cleans up existing Collabora containers
- Pulls Collabora CODE Docker image
- Starts Collabora on port 9980
- Configures allowed WOPI hosts
- Sets admin credentials

### `stop_services.sh`
- Stops WOPI server systemd service
- Stops Nginx
- Stops Collabora Docker container
- Shows final status

### `cleanup-collabora.sh`
- Stops all Collabora containers
- Removes Collabora containers
- Kills processes on port 9980
- Cleans up for fresh install

### `update_frontend_config.sh`
- Automatically detects Collabora URL
- Updates API base URL to production domain
- Updates Collabora server URL in frontend
- Reloads Nginx to apply changes
- Called automatically by frontend_deployment.sh

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `nginx-app-exp.conf` | Nginx configuration for reverse proxy |

## 📍 Deployment Locations

After deployment, files are located at:

| Component | Location |
|-----------|----------|
| Backend | `/opt/wopi-server/` |
| Documents | `/opt/wopi-server/documents/` |
| Frontend | `/var/www/app-exp-frontend/` |
| Nginx Config | `/etc/nginx/sites-available/app-exp` |
| Systemd Service | `/etc/systemd/system/wopi-server.service` |

## 🐛 Troubleshooting

**Scripts fail with permission error:**
```bash
sudo chmod +x *.sh
```

**Port 9980 already in use:**
```bash
sudo ./cleanup-collabora.sh
```

**Service won't start:**
```bash
# Check logs
sudo journalctl -u wopi-server -n 50
sudo docker logs --tail 50 collabora
```

**Frontend not loading:**
```bash
# Check Nginx
sudo nginx -t
sudo systemctl status nginx
```

## 📚 More Information

See the main **QUICK_START.md** in the repository root for complete deployment instructions.
