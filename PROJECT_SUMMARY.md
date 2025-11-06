# 📋 Project Summary

## Overview

Complete Collabora CODE integration with custom WOPI server and modern frontend.

**Goal:** Edit Microsoft Word documents (.docx) in a web browser using Collabora Online.

**Server:** app-exp.dev.lan

---

## 📁 Complete File Structure

```
/Users/ranjiththota/Desktop/WA/Coll-Test/
│
├── README.md                          # Main documentation
├── DEPLOYMENT_CHECKLIST.md            # Step-by-step deployment checklist
├── PROJECT_SUMMARY.md                 # This file
│
├── backend/                           # WOPI Server (Python)
│   ├── wopi_server.py                # Flask-based WOPI implementation
│   ├── requirements.txt              # Python dependencies (Flask, Flask-CORS)
│   └── documents/                    # Document storage
│       └── mydoc.docx               # Sample Word document
│
├── frontend/                          # Web Application
│   ├── index.html                    # Main HTML page
│   ├── app.js                        # JavaScript logic
│   └── styles.css                    # Modern CSS styling
│
└── deployment/                        # Deployment Scripts & Config
    ├── nginx-app-exp.conf            # Complete nginx configuration
    ├── deploy-backend.sh             # Backend deployment script
    ├── deploy-frontend.sh            # Frontend deployment script
    └── setup-collabora.sh            # Collabora Docker setup script
```

---

## 🏗️ Architecture

### Components

1. **Frontend (Browser)**
   - Modern HTML5/CSS3/JavaScript
   - Responsive design
   - Embeds Collabora editor in iframe
   - Location: `/var/www/app-exp-frontend`

2. **Nginx (Reverse Proxy)**
   - SSL termination
   - Routes requests to appropriate backends
   - Handles WebSocket connections
   - Config: `/etc/nginx/sites-available/app-exp`

3. **WOPI Server (Backend)**
   - Python Flask application
   - Implements WOPI protocol
   - Manages document storage and access
   - Port: 5001
   - Location: `/opt/wopi-server`

4. **Collabora CODE (Editor)**
   - LibreOffice Online
   - Runs in Docker container
   - Port: 9980
   - Docker image: `collabora/code`

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser                              │
│  https://app-exp.dev.lan                                   │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS (443)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Nginx Reverse Proxy                     │
│  ┌──────────────┬─────────────────┬────────────────────┐   │
│  │   /          │    /wopi/*      │   /browser/*       │   │
│  │   Frontend   │    WOPI Proxy   │   Collabora Proxy  │   │
│  └──────┬───────┴────────┬────────┴──────────┬─────────┘   │
└─────────┼────────────────┼───────────────────┼─────────────┘
          │                │                   │
          │                │                   │
          ▼                ▼                   ▼
    ┌─────────┐     ┌────────────┐     ┌──────────────┐
    │ Static  │     │    WOPI    │     │  Collabora   │
    │  Files  │     │   Server   │     │    CODE      │
    │         │     │ (Flask)    │     │  (Docker)    │
    │         │     │ Port 5001  │     │  Port 9980   │
    └─────────┘     └─────┬──────┘     └──────────────┘
                          │
                          ▼
                    ┌────────────┐
                    │ Documents  │
                    │  Storage   │
                    └────────────┘
```

---

## 🔄 Request Flow

### Opening a Document

1. User visits `https://app-exp.dev.lan`
2. Nginx serves `index.html`, `app.js`, `styles.css`
3. User clicks "Open mydoc.docx"
4. JavaScript constructs Collabora URL with WOPI parameters
5. Iframe loads Collabora editor from `/browser/.../cool.html`
6. Collabora requests document info from WOPI server:
   - `GET /wopi/files/mydoc` → CheckFileInfo
7. Collabora requests document content:
   - `GET /wopi/files/mydoc/contents` → GetFile
8. Document loads in editor
9. User can view and edit

### Saving Changes

1. User edits document in Collabora
2. Collabora auto-saves changes
3. Collabora sends updated content to WOPI server:
   - `POST /wopi/files/mydoc/contents` → PutFile
4. WOPI server writes new content to disk
5. Changes are saved

---

## 🔑 Key Files Explained

### Backend: `wopi_server.py`

**Purpose:** Implements the WOPI protocol for Collabora to access documents.

**Key Endpoints:**
- `GET /wopi/files/{file_id}` - Returns file metadata (CheckFileInfo)
- `GET /wopi/files/{file_id}/contents` - Returns file binary content
- `POST /wopi/files/{file_id}/contents` - Saves file changes

**Technologies:**
- Flask (Python web framework)
- Flask-CORS (Cross-Origin Resource Sharing)

**Features:**
- Removes security headers that block iframe embedding
- Provides file versioning via MD5 hash
- Supports both GET and POST for file contents
- Health check endpoint

---

### Frontend: `app.js`

**Purpose:** Client-side application that integrates with Collabora.

**Configuration:**
```javascript
const CONFIG = {
  serverDomain: "https://app-exp.dev.lan",
  wopiBase: "https://app-exp.dev.lan/wopi/files",
  collaboraServer: "https://app-exp.dev.lan/browser/.../cool.html",
  fileId: "mydoc",
  accessToken: "demo_token"
};
```

**Key Functions:**
- `openDocument()` - Loads document in Collabora iframe
- `closeDocument()` - Closes editor and resets UI
- `updateStatus()` - Updates status indicator

**Features:**
- Modern ES6 JavaScript
- Status indicators (ready, loading, error)
- iframe message handling
- WOPI server verification

---

### Frontend: `index.html`

**Purpose:** Main HTML structure with responsive design.

**Components:**
- Header with title and subtitle
- Control buttons (Open, Close)
- Status indicator
- Editor container with iframe
- Placeholder for when no document is open
- Footer with attribution

**Features:**
- Semantic HTML5
- SVG icons
- Accessibility features
- Mobile-responsive

---

### Frontend: `styles.css`

**Purpose:** Modern, responsive styling.

**Features:**
- CSS variables for theming
- Responsive design (mobile-friendly)
- Modern card-based layout
- Smooth animations and transitions
- Status indicator with pulse animation
- Professional color scheme

**Technologies:**
- CSS Grid and Flexbox
- CSS Custom Properties (variables)
- Modern CSS Reset
- Media queries for responsiveness

---

### Deployment: `nginx-app-exp.conf`

**Purpose:** Complete nginx configuration for all components.

**Key Sections:**

1. **SSL Configuration**
   - TLS 1.2/1.3
   - Certificate paths
   - Security settings

2. **Frontend Serving**
   - Static file serving
   - Gzip compression
   - Cache headers

3. **WOPI Proxy**
   - Proxies `/wopi/` to `http://localhost:5001`
   - CORS headers
   - No buffering for real-time updates

4. **Collabora Proxy**
   - Proxies `/browser/`, `/cool/`, etc. to `http://localhost:9980`
   - WebSocket support (CRITICAL)
   - Long timeouts for editing sessions

5. **WebSocket Configuration**
   - `location ~ ^/cool/(.*)/ws$` for document editing
   - Upgrade headers
   - 36000s timeout (10 hours)

**Important Notes:**
- WebSocket location MUST come before general `/cool` location
- Order matters in nginx configuration
- SSL termination handled by nginx (Collabora runs HTTP internally)

---

### Deployment: `deploy-backend.sh`

**Purpose:** Automated backend deployment.

**What It Does:**
1. Installs Python 3, pip, venv
2. Creates `/opt/wopi-server` directory
3. Copies `wopi_server.py`, `requirements.txt`, documents
4. Creates Python virtual environment
5. Installs Flask and dependencies
6. Creates systemd service
7. Sets proper permissions (www-data)
8. Starts and enables service
9. Tests health endpoint

**Usage:**
```bash
cd ~/collabora-deploy/backend
sudo ../deployment/deploy-backend.sh
```

---

### Deployment: `deploy-frontend.sh`

**Purpose:** Automated frontend deployment.

**What It Does:**
1. Installs nginx
2. Creates `/var/www/app-exp-frontend` directory
3. Copies HTML, JS, CSS files
4. Sets proper permissions
5. Copies nginx configuration
6. Tests nginx config
7. Reloads nginx

**Usage:**
```bash
cd ~/collabora-deploy/deployment
sudo ./deploy-frontend.sh
```

---

### Deployment: `setup-collabora.sh`

**Purpose:** Automated Collabora CODE setup.

**What It Does:**
1. Installs Docker
2. Stops/removes existing Collabora container
3. Pulls latest `collabora/code` image
4. Starts container with correct parameters:
   - Domain: `app-exp\\.dev\\.lan`
   - SSL termination mode
   - Frame ancestors allowed
   - Admin credentials
5. Waits for container to be ready
6. Tests discovery endpoint
7. Extracts and displays editor URL

**Usage:**
```bash
cd ~/collabora-deploy/deployment
sudo ./setup-collabora.sh
```

**Important Parameters:**
- `domain=app-exp\\.dev\\.lan` - Trusted WOPI host
- `--o:ssl.enable=false` - SSL handled by nginx
- `--o:ssl.termination=true` - Nginx does SSL termination
- `--o:net.frame_ancestors=*` - Allow iframe embedding

---

## 🔐 Security Considerations

### Current Setup (Development)

- Simple access token ("demo_token")
- No authentication required
- Frame ancestors set to "*" (allows any domain to embed)
- CORS fully open
- Self-signed SSL certificates

### For Production

**Must Do:**
1. **Implement proper authentication**
   - JWT tokens
   - OAuth integration
   - Session management

2. **Restrict frame ancestors**
   - Change `--o:net.frame_ancestors=*` to specific domains
   - Update CORS to allow only your domain

3. **Use real SSL certificates**
   - Let's Encrypt (free)
   - Commercial certificate

4. **Add access control**
   - User authentication
   - Document permissions
   - Access logging

5. **Secure passwords**
   - Change Collabora admin password
   - Store credentials securely

6. **Enable monitoring**
   - Log aggregation
   - Intrusion detection
   - Rate limiting

---

## 📊 Port Usage

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Nginx | 443 | HTTPS | Public access, SSL termination |
| Nginx | 80 | HTTP | Redirect to HTTPS |
| WOPI Server | 5001 | HTTP | Internal - WOPI protocol |
| Collabora | 9980 | HTTP | Internal - Document editing |

**Note:** Only ports 80 and 443 need to be accessible from outside. Ports 5001 and 9980 are internal only.

---

## 🧪 Testing Endpoints

```bash
# Frontend
curl -k https://app-exp.dev.lan/

# WOPI Server (through nginx)
curl -k https://app-exp.dev.lan/wopi/files/mydoc

# WOPI Server (direct)
curl http://localhost:5001/wopi/files/mydoc

# WOPI Health
curl http://localhost:5001/health

# Collabora Discovery (through nginx)
curl -k https://app-exp.dev.lan/hosting/discovery

# Collabora Discovery (direct)
curl http://localhost:9980/hosting/discovery

# Nginx Health
curl -k https://app-exp.dev.lan/health
```

---

## 📝 Environment Requirements

### Server Specifications

**Minimum:**
- CPU: 2 cores
- RAM: 4 GB
- Disk: 20 GB
- OS: Ubuntu 20.04+ (or similar Linux)

**Recommended:**
- CPU: 4 cores
- RAM: 8 GB
- Disk: 50 GB
- OS: Ubuntu 22.04 LTS

### Software Requirements

- Docker 20.10+
- Python 3.8+
- Nginx 1.18+
- OpenSSL (for SSL certificates)

---

## 🚀 Quick Commands Reference

### Service Management

```bash
# Restart everything
sudo systemctl restart wopi-server nginx
sudo docker restart collabora

# Check status
sudo systemctl status wopi-server
sudo systemctl status nginx
sudo docker ps | grep collabora

# View logs
sudo journalctl -u wopi-server -f
sudo tail -f /var/log/nginx/app-exp-error.log
sudo docker logs -f collabora
```

### File Locations

```bash
# Frontend files
ls -la /var/www/app-exp-frontend/

# Backend files
ls -la /opt/wopi-server/

# Documents
ls -la /opt/wopi-server/documents/

# Nginx config
sudo nano /etc/nginx/sites-available/app-exp

# Systemd service
sudo nano /etc/systemd/system/wopi-server.service
```

---

## 📖 Next Steps After Deployment

1. **Test thoroughly**
   - Open different documents
   - Test concurrent users
   - Verify saving works

2. **Add more documents**
   - Copy .docx files to `/opt/wopi-server/documents/`
   - Update frontend to allow file selection

3. **Implement authentication**
   - Add user login
   - Secure WOPI endpoints
   - Implement proper access tokens

4. **Monitor performance**
   - Set up log monitoring
   - Configure alerts
   - Monitor resource usage

5. **Plan for scale**
   - Load balancing
   - Database for document metadata
   - Distributed file storage

---

## 🎓 Learning Resources

- **WOPI Protocol:** https://wopi.readthedocs.io/
- **Collabora Online:** https://sdk.collaboraonline.com/
- **Flask:** https://flask.palletsprojects.com/
- **Nginx:** https://nginx.org/en/docs/

---

**Project Created:** 2025-11-06
**Status:** Ready for Deployment
**Version:** 1.0
