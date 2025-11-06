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

## 🚀 5-Step Deployment

### 1️⃣ Copy Files to Server (2 min)

```bash
# On your LOCAL machine, from this directory:
ssh user@app-exp.dev.lan "mkdir -p ~/collabora-deploy"
scp -r backend frontend deployment user@app-exp.dev.lan:~/collabora-deploy/
```

### 2️⃣ Setup Collabora (3 min)

```bash
# SSH into server
ssh user@app-exp.dev.lan

# Run Collabora setup
cd ~/collabora-deploy/deployment
chmod +x *.sh
sudo ./setup-collabora.sh
```

**⚠️ IMPORTANT:** Copy the "Editor URL" shown at the end. You'll need it in step 4!

### 3️⃣ Deploy Backend (2 min)

```bash
# Still on the server
cd ~/collabora-deploy/backend
sudo ../deployment/deploy-backend.sh
```

### 4️⃣ Update Frontend Config (1 min)

```bash
# Get editor URL
curl -s http://localhost:9980/hosting/discovery | grep urlsrc | head -1

# Edit frontend config
cd ~/collabora-deploy/frontend
nano app.js

# Update line 17:
# collaboraServer: "https://app-exp.dev.lan/browser/YOUR_HASH/cool.html"
# Save with Ctrl+X, Y, Enter
```

### 5️⃣ Deploy Frontend (2 min)

```bash
cd ~/collabora-deploy/deployment
sudo ./deploy-frontend.sh
```

## ✅ Test It

Open your browser:

```
https://app-exp.dev.lan
```

Click **"Open mydoc.docx"** → Document should load in editor!

## 🐛 Quick Troubleshooting

### Document doesn't load?

```bash
# Check all services
sudo systemctl status wopi-server nginx
sudo docker ps | grep collabora

# Check logs
sudo journalctl -u wopi-server --since "5 minutes ago"
sudo tail -50 /var/log/nginx/app-exp-error.log
```

### Still not working?

Check browser console (F12 → Console) for errors, then see full **README.md** for detailed troubleshooting.

## 📚 What's Next?

- ✅ Test document editing and saving
- ✅ Add more documents to `/opt/wopi-server/documents/`
- ✅ Review security settings in **README.md**
- ✅ Follow **DEPLOYMENT_CHECKLIST.md** for production setup

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

## 💡 Tips

1. **Always check logs first** when troubleshooting
2. **Make scripts executable** before running: `chmod +x *.sh`
3. **Update frontend config** before deploying (step 4)
4. **Save the admin password** from step 2

---

**Ready?** Start with Step 1 above! 🚀
