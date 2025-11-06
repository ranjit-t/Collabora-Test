# 📁 Complete File Index

All files created for the Collabora CODE Integration Project.

## 📚 Documentation Files (Read These First!)

| File | Purpose | When to Use |
|------|---------|-------------|
| **QUICK_START.md** | Fastest way to deploy (10 min) | For quick deployment |
| **DEPLOYMENT_CHECKLIST.md** | Step-by-step deployment checklist | For careful, verified deployment |
| **README.md** | Complete documentation | For understanding everything |
| **PROJECT_SUMMARY.md** | Technical architecture details | For understanding how it works |
| **FILE_INDEX.md** | This file - complete file listing | For navigation |

## 💻 Backend Files (WOPI Server)

| File | Location | Purpose |
|------|----------|---------|
| **wopi_server.py** | `backend/` | Main WOPI server (Flask application) |
| **requirements.txt** | `backend/` | Python dependencies (Flask, Flask-CORS) |
| **mydoc.docx** | `backend/documents/` | Sample Word document |

### Backend Details

**wopi_server.py** (200+ lines)
- Implements WOPI protocol
- CheckFileInfo endpoint
- GetFile endpoint
- PutFile endpoint
- Health check endpoint
- Runs on port 5001

**Deploy Location:** `/opt/wopi-server/` on server

## 🎨 Frontend Files (Web Application)

| File | Location | Purpose |
|------|----------|---------|
| **index.html** | `frontend/` | Main HTML page with UI |
| **app.js** | `frontend/` | JavaScript application logic |
| **styles.css** | `frontend/` | Modern CSS styling |

### Frontend Details

**index.html** (50+ lines)
- Responsive design
- Document editor container
- Control buttons
- Status indicators

**app.js** (200+ lines)
- Configuration section (UPDATE THIS!)
- Document opening/closing logic
- Status management
- Collabora integration

**styles.css** (300+ lines)
- Modern, responsive design
- CSS variables for theming
- Mobile-friendly
- Professional styling

**Deploy Location:** `/var/www/app-exp-frontend/` on server

## 🚀 Deployment Files (Scripts & Configuration)

| File | Location | Purpose | Executable |
|------|----------|---------|------------|
| **nginx-app-exp.conf** | `deployment/` | Complete nginx configuration | No |
| **setup-collabora.sh** | `deployment/` | Collabora Docker setup script | Yes |
| **deploy-backend.sh** | `deployment/` | Backend deployment script | Yes |
| **deploy-frontend.sh** | `deployment/` | Frontend deployment script | Yes |

### Deployment Details

**nginx-app-exp.conf** (200+ lines)
- Complete nginx configuration
- SSL termination
- Frontend serving
- WOPI proxy
- Collabora proxy with WebSocket support
- Health check endpoints

**Deploy Location:** `/etc/nginx/sites-available/app-exp` on server

**setup-collabora.sh** (200+ lines)
- Installs Docker
- Pulls Collabora image
- Configures container
- Starts Collabora CODE
- Tests endpoints
- Shows editor URL

**Run with:** `sudo ./setup-collabora.sh`

**deploy-backend.sh** (150+ lines)
- Installs Python 3
- Creates virtual environment
- Installs dependencies
- Creates systemd service
- Sets permissions
- Starts WOPI server

**Run with:** `sudo ./deploy-backend.sh`

**deploy-frontend.sh** (120+ lines)
- Installs nginx
- Copies frontend files
- Updates nginx config
- Sets permissions
- Reloads nginx

**Run with:** `sudo ./deploy-frontend.sh`

## 📄 Legacy/Old Files (Can Be Ignored)

These files were from earlier iterations and are superseded by the organized structure:

| File | Status | Note |
|------|--------|------|
| `app.js` (root) | Old | Use `frontend/app.js` instead |
| `index.html` (root) | Old | Use `frontend/index.html` instead |
| `wopi_server.py` (root) | Old | Use `backend/wopi_server.py` instead |
| `default.conf` (root) | Old | Use `deployment/nginx-app-exp.conf` instead |
| `DEPLOYMENT_GUIDE.md` | Old | Use `QUICK_START.md` or `README.md` instead |
| `collabora docker.md` | Notes | Reference only |

## 🗂️ Organized Project Structure

**Use These Organized Directories:**

```
Coll-Test/
├── backend/                    ← Backend files
│   ├── wopi_server.py
│   ├── requirements.txt
│   └── documents/
│       └── mydoc.docx
│
├── frontend/                   ← Frontend files
│   ├── index.html
│   ├── app.js
│   └── styles.css
│
└── deployment/                 ← Deployment scripts
    ├── nginx-app-exp.conf
    ├── setup-collabora.sh
    ├── deploy-backend.sh
    └── deploy-frontend.sh
```

## 📊 File Count Summary

| Category | Count | Total Lines |
|----------|-------|-------------|
| Documentation | 5 files | ~2,000+ lines |
| Backend | 2 files | ~250 lines |
| Frontend | 3 files | ~550 lines |
| Deployment | 4 files | ~650 lines |
| **Total** | **14 files** | **~3,450+ lines** |

## 🎯 Which Files to Edit

### Before Deployment

**Must Edit:**
1. `frontend/app.js` - Update `CONFIG.collaboraServer` with your editor URL

**Optional Edit:**
1. `deployment/setup-collabora.sh` - Change `ADMIN_PASSWORD`

### After Deployment (Production)

**Should Edit:**
1. `backend/wopi_server.py` - Add authentication
2. `frontend/app.js` - Add real access tokens
3. `deployment/nginx-app-exp.conf` - Tighten security

## 📦 Files to Copy to Server

**Everything in these directories:**
```bash
scp -r backend frontend deployment user@app-exp.dev.lan:~/collabora-deploy/
```

This copies:
- `backend/` (3 items: wopi_server.py, requirements.txt, documents/)
- `frontend/` (3 items: index.html, app.js, styles.css)
- `deployment/` (4 items: all .sh scripts and nginx config)

**Total:** ~10 items

## 🔍 File Locations After Deployment

| Component | Source | Destination on Server |
|-----------|--------|----------------------|
| WOPI Server | `backend/` | `/opt/wopi-server/` |
| Frontend | `frontend/` | `/var/www/app-exp-frontend/` |
| Nginx Config | `deployment/nginx-app-exp.conf` | `/etc/nginx/sites-available/app-exp` |
| Systemd Service | Created by script | `/etc/systemd/system/wopi-server.service` |
| Collabora | Docker container | Container: `collabora` |

## 📝 Key Configuration Values

### In frontend/app.js (Lines 9-17)

```javascript
const CONFIG = {
  serverDomain: "https://app-exp.dev.lan",
  wopiBase: "https://app-exp.dev.lan/wopi/files",
  collaboraServer: "https://app-exp.dev.lan/browser/HASH/cool.html", // UPDATE THIS!
  fileId: "mydoc",
  accessToken: "demo_token"
};
```

### In deployment/setup-collabora.sh (Lines 14-17)

```bash
DOMAIN="app-exp\\.dev\\.lan"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="SecurePassword123"  # CHANGE THIS!
```

### In deployment/nginx-app-exp.conf (Lines 9-11)

```nginx
ssl_certificate /etc/ssl/certs/app-exp-dev/cert.pem;
ssl_certificate_key /etc/ssl/private/app-exp-dev/key.pem;
```

## 🚀 Deployment Order

1. **setup-collabora.sh** - Sets up Collabora CODE
2. **deploy-backend.sh** - Deploys WOPI server
3. **Edit frontend/app.js** - Update Collabora URL
4. **deploy-frontend.sh** - Deploys frontend

## ✅ Verification Checklist

After deployment, these files should exist on server:

```bash
# Backend
/opt/wopi-server/wopi_server.py
/opt/wopi-server/requirements.txt
/opt/wopi-server/documents/mydoc.docx
/opt/wopi-server/venv/

# Frontend
/var/www/app-exp-frontend/index.html
/var/www/app-exp-frontend/app.js
/var/www/app-exp-frontend/styles.css

# Configuration
/etc/nginx/sites-available/app-exp
/etc/nginx/sites-enabled/app-exp
/etc/systemd/system/wopi-server.service

# Docker
docker ps | grep collabora  # Should show running container
```

## 📖 Documentation Reading Order

1. **QUICK_START.md** - Get started immediately
2. **DEPLOYMENT_CHECKLIST.md** - Follow step-by-step
3. **README.md** - Understand the full system
4. **PROJECT_SUMMARY.md** - Deep dive into architecture
5. **FILE_INDEX.md** - Navigate all files (you are here!)

---

**Total Project Size:** ~3,500 lines of code and documentation
**Deployment Time:** 10-15 minutes
**Complexity:** Intermediate
**Production Ready:** With security enhancements (see README.md)

---

All files are ready for deployment! Start with **QUICK_START.md** 🚀
