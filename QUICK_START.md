# ⚡ Quick Start Guide

**Deploy in 3 simple steps!**

## What You'll Get

✅ Document management web interface
✅ Upload, edit, download documents
✅ Collabora CODE editor (LibreOffice Online)
✅ Support for Word, Excel, PowerPoint files

---

## Prerequisites

- **Linux server** (Ubuntu 20.04+)
- **SSH access** with sudo privileges
- **Domain**: `app-exp.dev.lan` (or your domain)
- **SSL certificates** ready
- **Docker** installed

---

## 🚀 Deployment

### Option 1: Deploy Everything at Once (Recommended)

```bash
# SSH to your server
ssh user@app-exp.dev.lan

# Clone repository
git clone https://github.com/ranjit-t/Collabora-Test.git
cd Collabora-Test/deployment

# Make scripts executable
chmod +x *.sh

# Deploy everything
sudo ./deploy_all.sh
```

That's it! The script will:
1. Deploy Collabora CODE
2. Deploy Backend (WOPI Server)
3. Deploy Frontend (Web Interface)

---

### Option 2: Deploy Step by Step

If you prefer manual control:

```bash
# SSH to your server
ssh user@app-exp.dev.lan

# Clone repository
git clone https://github.com/ranjit-t/Collabora-Test.git
cd Collabora-Test/deployment
chmod +x *.sh

# Step 1: Deploy Collabora
sudo ./setup-collabora.sh

# Step 2: Deploy Backend
sudo ./backend_deployment.sh

# Step 3: Deploy Frontend
sudo ./frontend_deployment.sh
```

---

## ⚙️ Post-Deployment (Optional)

**Frontend configuration is now automatic!** The deployment script automatically detects and configures the Collabora URL.

If you need to manually update the configuration:

```bash
sudo ./deployment/update_frontend_config.sh
```

---

## ✅ Verify Deployment

```bash
# Check all services
sudo systemctl status wopi-server nginx
sudo docker ps | grep collabora

# Test endpoints
curl http://localhost:5001/health
curl -k https://app-exp.dev.lan/health
```

**Access your app:**
```
https://app-exp.dev.lan
```

---

## 🔄 Service Management

### Start All Services
```bash
sudo systemctl start wopi-server nginx
sudo docker start collabora
```

### Stop All Services
```bash
cd ~/Collabora-Test/deployment
sudo ./stop_services.sh
```

### Restart Services
```bash
sudo systemctl restart wopi-server nginx
sudo docker restart collabora
```

### View Logs
```bash
# WOPI Server logs
sudo journalctl -u wopi-server -f

# Nginx logs
sudo tail -f /var/log/nginx/app-exp-error.log

# Collabora logs
sudo docker logs -f collabora
```

---

## 🔄 Updating from GitHub

When you push changes to GitHub:

```bash
cd ~/Collabora-Test
git pull origin main

# Stop services
sudo ./deployment/stop_services.sh

# Redeploy
cd deployment
sudo ./deploy_all.sh
```

### Quick Updates (Specific Components)

**Frontend only:**
```bash
cd ~/Collabora-Test
git pull
sudo ./deployment/frontend_deployment.sh
```

**Backend only:**
```bash
cd ~/Collabora-Test
git pull
sudo ./deployment/backend_deployment.sh
```

**Nginx config only:**
```bash
cd ~/Collabora-Test
git pull
sudo cp deployment/nginx-app-exp.conf /etc/nginx/sites-available/app-exp
sudo nginx -t && sudo systemctl reload nginx
```

---

## 🐛 Troubleshooting

### Collabora port already in use?
```bash
cd ~/Collabora-Test/deployment
sudo ./cleanup-collabora.sh
sudo ./setup-collabora.sh
```

### Service not starting?
```bash
# Check logs
sudo journalctl -u wopi-server -n 50
sudo tail -50 /var/log/nginx/app-exp-error.log
sudo docker logs --tail 50 collabora

# Restart services
sudo systemctl restart wopi-server nginx
sudo docker restart collabora
```

### Can't see documents?
```bash
# Check documents directory
ls -la /opt/wopi-server/documents/

# Fix permissions
sudo chown -R www-data:www-data /opt/wopi-server/documents/
sudo chmod 755 /opt/wopi-server/documents/
```

### Nginx errors?
```bash
# Test configuration
sudo nginx -t

# Check for conflicts
ls -la /etc/nginx/sites-enabled/

# Remove conflicting configs
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl reload nginx
```

---

## 📁 Important Locations

| Component | Location |
|-----------|----------|
| Backend | `/opt/wopi-server/` |
| Documents | `/opt/wopi-server/documents/` |
| Frontend | `/var/www/app-exp-frontend/` |
| Nginx config | `/etc/nginx/sites-available/app-exp` |
| Logs (WOPI) | `journalctl -u wopi-server` |
| Logs (Nginx) | `/var/log/nginx/app-exp-error.log` |
| Logs (Collabora) | `docker logs collabora` |

---

## 📝 Available Scripts

All scripts are in the `deployment/` directory:

| Script | Purpose |
|--------|---------|
| `deploy_all.sh` | Deploy everything at once |
| `setup-collabora.sh` | Deploy Collabora CODE only |
| `backend_deployment.sh` | Deploy WOPI server only |
| `frontend_deployment.sh` | Deploy web interface only |
| `stop_services.sh` | Stop all services |
| `cleanup-collabora.sh` | Clean up Collabora issues |

---

## 💡 Usage

After deployment:

1. **Open** `https://app-exp.dev.lan`
2. **Upload** documents using the Upload button
3. **Click** any document to edit
4. **Download** edited documents
5. **Delete** documents you don't need

All changes are automatically saved!

---

## 🆘 Need Help?

- **Logs**: Always check logs first when troubleshooting
- **Configuration**: Verify Collabora URL in frontend config
- **Permissions**: Ensure www-data owns all files
- **Services**: Make sure all three services are running

For detailed documentation, see **README.md**

---

**That's it! Your document management system is ready to use.** 🎉
