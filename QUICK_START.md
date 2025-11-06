# ⚡ Quick Start Guide

**Get up and running in 10 minutes!**

## What You'll Deploy

A complete document editing system with:
- ✅ Modern web interface
- ✅ Collabora CODE (LibreOffice Online)
- ✅ WOPI server for document management
- ✅ Nginx reverse proxy with SSL

## Prerequisites

- Linux server with Ubuntu 20.04+
- SSH access with sudo privileges
- Domain: `app-exp.dev.lan` configured
- SSL certificates available
- Git installed on server

## 🚀 5-Step Deployment

### 1️⃣ Clone Repository on Server (1 min)

```bash
# SSH into your server
ssh user@app-exp.dev.lan

# Install git if not already installed
sudo apt-get update && sudo apt-get install -y git

# Clone the repository
git clone https://github.com/ranjit-t/Collabora-Test.git
cd Collabora-Test
```

### 2️⃣ Setup Collabora (3 min)

```bash
# Make scripts executable
cd deployment
chmod +x *.sh

# Run Collabora setup
sudo ./setup-collabora.sh
```

**⚠️ IMPORTANT:** Copy the "Editor URL" shown at the end. You'll need it in step 4!

### 3️⃣ Deploy Backend (2 min)

```bash
# Deploy WOPI server
cd ../backend
sudo ../deployment/deploy-backend.sh
```

### 4️⃣ Update Frontend Config (1 min)

```bash
# Get editor URL
curl -s http://localhost:9980/hosting/discovery | grep urlsrc | head -1

# Edit frontend config
cd ../frontend
nano app.js

# Update line 17:
# collaboraServer: "https://app-exp.dev.lan/browser/YOUR_HASH/cool.html"
# Save with Ctrl+X, Y, Enter
```

### 5️⃣ Deploy Frontend (2 min)

```bash
cd ../deployment
sudo ./deploy-frontend.sh
```

## ✅ Verify Services

After deployment, verify everything is running:

```bash
# Check all services
sudo systemctl status wopi-server
sudo systemctl status nginx
sudo docker ps | grep collabora

# Test nginx configuration
sudo nginx -t

# If you made any changes, reload nginx
sudo systemctl reload nginx

# Restart Collabora if needed
sudo docker restart collabora

# View logs if troubleshooting
sudo journalctl -u wopi-server -f          # WOPI server logs
sudo tail -f /var/log/nginx/app-exp-error.log  # Nginx logs
sudo docker logs -f collabora              # Collabora logs
```

## 🧪 Test Endpoints

```bash
# Test WOPI server
curl http://localhost:5001/health
curl http://localhost:5001/wopi/files/mydoc

# Test through nginx
curl -k https://app-exp.dev.lan/health
curl -k https://app-exp.dev.lan/wopi/files/mydoc

# Test Collabora discovery
curl -k https://app-exp.dev.lan/hosting/discovery
```

## ✅ Test in Browser

Open your browser:

```
https://app-exp.dev.lan
```

Click **"Open mydoc.docx"** → Document should load in editor!

If it doesn't work, press F12 and check the Console tab for errors.

## 🐛 Quick Troubleshooting

### Collabora: "port already allocated" error?

If you get "Bind for 0.0.0.0:9980 failed: port is already allocated":

```bash
# Run the cleanup script
cd ~/Collabora-Test/deployment
sudo ./cleanup-collabora.sh

# Then run setup again
sudo ./setup-collabora.sh
```

Or manually clean up:

```bash
# Stop all collabora containers
docker ps -a | grep collabora | awk '{print $1}' | xargs docker stop
docker ps -a | grep collabora | awk '{print $1}' | xargs docker rm

# Kill processes on port 9980
sudo fuser -k 9980/tcp

# Verify port is free
sudo lsof -i :9980

# If still in use, restart Docker
sudo systemctl restart docker
```

### Document doesn't load?

```bash
# Check all services
sudo systemctl status wopi-server nginx
sudo docker ps | grep collabora

# Check logs
sudo journalctl -u wopi-server --since "5 minutes ago"
sudo tail -50 /var/log/nginx/app-exp-error.log
sudo docker logs --tail 50 collabora
```

### WOPI Server not responding?

```bash
# Check if service is running
sudo systemctl status wopi-server

# Restart it
sudo systemctl restart wopi-server

# Check logs for errors
sudo journalctl -u wopi-server -n 100
```

### Nginx errors?

```bash
# Test configuration
sudo nginx -t

# Check logs
sudo tail -100 /var/log/nginx/app-exp-error.log

# Reload nginx
sudo systemctl reload nginx
```

### Still not working?

Check browser console (F12 → Console) for errors, then see full **README.md** for detailed troubleshooting.

## 📚 What's Next?

- ✅ Test document editing and saving
- ✅ Add more documents to `/opt/wopi-server/documents/`
- ✅ Review security settings in **README.md**
- ✅ Follow **DEPLOYMENT_CHECKLIST.md** for production setup

## 🔧 Service Management Commands

### Restart Services

```bash
# Restart individual services
sudo systemctl restart wopi-server
sudo systemctl restart nginx
sudo docker restart collabora

# Restart all at once
sudo systemctl restart wopi-server nginx && sudo docker restart collabora
```

### Stop Services

```bash
sudo systemctl stop wopi-server
sudo systemctl stop nginx
sudo docker stop collabora
```

### Start Services

```bash
sudo systemctl start wopi-server
sudo systemctl start nginx
sudo docker start collabora
```

### Check Service Status

```bash
# Quick status check
sudo systemctl is-active wopi-server nginx
sudo docker ps | grep collabora

# Detailed status
sudo systemctl status wopi-server --no-pager
sudo systemctl status nginx --no-pager
sudo docker ps -a | grep collabora
```

### View Logs

```bash
# Follow logs in real-time (Ctrl+C to exit)
sudo journalctl -u wopi-server -f
sudo tail -f /var/log/nginx/app-exp-error.log
sudo docker logs -f collabora

# View last 50 lines
sudo journalctl -u wopi-server -n 50
sudo tail -50 /var/log/nginx/app-exp-error.log
sudo docker logs --tail 50 collabora

# View logs from last 10 minutes
sudo journalctl -u wopi-server --since "10 minutes ago"
```

### Nginx Commands

```bash
# Test configuration (always do this before reload!)
sudo nginx -t

# Reload nginx (applies config changes without downtime)
sudo systemctl reload nginx

# Restart nginx (full restart)
sudo systemctl restart nginx

# Check nginx syntax
sudo nginx -T | less
```

### Collabora Commands

```bash
# Restart Collabora
sudo docker restart collabora

# View Collabora status
sudo docker ps | grep collabora
sudo docker inspect collabora | grep -i status

# View Collabora logs
sudo docker logs collabora | tail -100
sudo docker logs -f collabora

# Get Collabora version
sudo docker exec collabora /opt/collaboraoffice/program/soffice --version
```

### Update Configuration

```bash
# After editing nginx config
sudo nginx -t && sudo systemctl reload nginx

# After editing WOPI server code
sudo systemctl restart wopi-server

# After changing Collabora settings
sudo docker restart collabora
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `README.md` | Complete documentation |
| `DEPLOYMENT_CHECKLIST.md` | Step-by-step checklist |
| `PROJECT_SUMMARY.md` | Architecture & details |
| `backend/wopi_server.py` | WOPI server code |
| `frontend/app.js` | Frontend configuration |
| `deployment/nginx-app-exp.conf` | Nginx config |

## 🎯 Access Points

After successful deployment:

- **Frontend:** https://app-exp.dev.lan
- **Collabora Admin:** https://app-exp.dev.lan/browser/dist/admin/admin.html
  - Username: `admin`
  - Password: (set in `setup-collabora.sh`, default: `SecurePassword123`)

## 📍 Important File Locations on Server

```bash
# Backend (WOPI Server)
/opt/wopi-server/wopi_server.py          # WOPI server code
/opt/wopi-server/documents/              # Document storage
/etc/systemd/system/wopi-server.service  # Systemd service file

# Frontend
/var/www/app-exp-frontend/               # Frontend files

# Nginx
/etc/nginx/sites-available/app-exp       # Nginx configuration
/etc/nginx/sites-enabled/app-exp         # Nginx enabled site (symlink)
/var/log/nginx/app-exp-error.log         # Nginx error logs
/var/log/nginx/app-exp-access.log        # Nginx access logs

# Collabora
# Docker container named 'collabora' on port 9980
```

## 🔄 Updating from GitHub (Redeployment)

When you push updates to GitHub and need to deploy them to the server:

### Full Update (All Components)

```bash
# SSH to your server
ssh user@app-exp.dev.lan
cd ~/Collabora-Test

# Stop services
sudo systemctl stop wopi-server nginx
sudo docker stop collabora

# Pull latest changes
git pull origin main

# Redeploy in order
cd deployment
chmod +x *.sh

# 1. Update Collabora (if Docker config changed)
sudo ./setup-collabora.sh

# 2. Redeploy backend
cd ../backend
sudo ../deployment/deploy-backend.sh

# 3. Update frontend config if needed
cd ../frontend
nano app.js  # If Collabora URL changed

# 4. Redeploy frontend
cd ../deployment
sudo ./deploy-frontend.sh

# Verify everything is running
sudo systemctl status wopi-server nginx --no-pager
sudo docker ps | grep collabora
```

### Quick Update (Frontend Only)

If you only changed frontend files (HTML/CSS/JS):

```bash
cd ~/Collabora-Test
git pull

# Copy new frontend files
sudo cp frontend/* /var/www/app-exp-frontend/
sudo chown www-data:www-data /var/www/app-exp-frontend/*

# Reload nginx
sudo systemctl reload nginx
```

### Quick Update (Backend Only)

If you only changed backend code:

```bash
cd ~/Collabora-Test
git pull

# Copy new backend files
sudo cp backend/wopi_server.py /opt/wopi-server/
sudo cp backend/requirements.txt /opt/wopi-server/

# Reinstall dependencies if requirements.txt changed
cd /opt/wopi-server
sudo ./venv/bin/pip install -r requirements.txt

# Restart WOPI server
sudo systemctl restart wopi-server

# Check status
sudo systemctl status wopi-server
```

### Quick Update (Nginx Config Only)

If you only changed nginx configuration:

```bash
cd ~/Collabora-Test
git pull

# Copy new nginx config
sudo cp deployment/nginx-app-exp.conf /etc/nginx/sites-available/app-exp

# Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

### Update Documents

If you added/updated documents:

```bash
cd ~/Collabora-Test
git pull

# Copy new documents
sudo cp backend/documents/* /opt/wopi-server/documents/
sudo chown www-data:www-data /opt/wopi-server/documents/*
sudo chmod 644 /opt/wopi-server/documents/*

# No restart needed - documents are read on demand
```

### Verification After Update

```bash
# Check all services
sudo systemctl is-active wopi-server nginx
sudo docker ps | grep collabora

# Test endpoints
curl http://localhost:5001/health
curl -k https://app-exp.dev.lan/health

# View logs for errors
sudo journalctl -u wopi-server -n 50
sudo tail -50 /var/log/nginx/app-exp-error.log
sudo docker logs --tail 50 collabora
```

### Rollback (If Something Breaks)

```bash
cd ~/Collabora-Test

# Go back to previous commit
git log --oneline -5  # Find the commit hash
git checkout <previous-commit-hash>

# Redeploy the previous version
# Follow the appropriate update steps above

# Or reset to a specific version
git reset --hard <commit-hash>
git pull  # If you want to re-sync with remote
```

## 💡 Tips

1. **Always check logs first** when troubleshooting
2. **Test nginx config** before reload: `sudo nginx -t`
3. **Make scripts executable** before running: `chmod +x *.sh`
4. **Update frontend config** before deploying (step 4)
5. **Save the admin password** from step 2
6. **Use reload not restart** for nginx when possible
7. **Check service status** after any changes
8. **Always `git pull` before making changes** on the server
9. **Stop services before full redeployment**
10. **Test after every update** - don't assume it works!

## 🎯 Common Update Scenarios

| What Changed | Commands |
|--------------|----------|
| Frontend HTML/CSS/JS | `git pull` → Copy to `/var/www/app-exp-frontend/` → `systemctl reload nginx` |
| Backend Python code | `git pull` → Copy to `/opt/wopi-server/` → `systemctl restart wopi-server` |
| Nginx config | `git pull` → Copy config → `nginx -t` → `systemctl reload nginx` |
| Documents | `git pull` → Copy to `/opt/wopi-server/documents/` → No restart |
| Requirements.txt | `git pull` → Copy → Reinstall in venv → `systemctl restart wopi-server` |
| Everything | Full redeployment process above |

---

**Ready?** Start with Step 1 above! 🚀
