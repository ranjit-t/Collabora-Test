# Collabora CODE Integration Project

Complete setup for integrating Collabora CODE with a custom WOPI server and frontend application.

## 📁 Project Structure

```
Coll-Test/
├── backend/                    # WOPI Server (Python Flask)
│   ├── wopi_server.py         # Main WOPI server implementation
│   ├── requirements.txt       # Python dependencies
│   └── documents/             # Document storage
│       └── mydoc.docx        # Sample document
│
├── frontend/                  # Frontend Application
│   ├── index.html            # Main HTML page
│   ├── app.js                # JavaScript application logic
│   └── styles.css            # CSS styling
│
└── deployment/               # Deployment Scripts & Config
    ├── nginx-app-exp.conf   # Complete nginx configuration
    ├── deploy-backend.sh    # Backend deployment script
    ├── deploy-frontend.sh   # Frontend deployment script
    └── setup-collabora.sh   # Collabora Docker setup script
```

## 🎯 What This Does

This project allows you to:
- View and edit Word documents (.docx) in a web browser
- Use Collabora CODE (LibreOffice Online) as the document editor
- Implement the WOPI protocol for document operations
- Host everything on your own server (app-exp.dev.lan)

## 🚀 Quick Start Deployment

### Prerequisites

- Linux server (Ubuntu 20.04+ recommended)
- Root/sudo access
- Domain: app-exp.dev.lan configured
- SSL certificates for the domain

### Step 1: Copy Files to Server

From your local machine, copy all files to the server:

```bash
# Create deployment directory on server
ssh user@app-exp.dev.lan "mkdir -p ~/collabora-deploy"

# Copy all files
scp -r backend frontend deployment user@app-exp.dev.lan:~/collabora-deploy/
```

### Step 2: Deploy Collabora CODE

SSH into your server and run:

```bash
ssh user@app-exp.dev.lan
cd ~/collabora-deploy/deployment

# Make scripts executable
chmod +x *.sh

# Run Collabora setup
sudo ./setup-collabora.sh
```

This will:
- Install Docker (if needed)
- Pull Collabora CODE image
- Start Collabora container on port 9980
- Configure it for your domain

**IMPORTANT:** After this completes, note the editor URL shown at the end.

### Step 3: Deploy Backend (WOPI Server)

```bash
cd ~/collabora-deploy/backend
sudo ../deployment/deploy-backend.sh
```

This will:
- Install Python 3 and dependencies
- Create virtual environment
- Install Flask and Flask-CORS
- Create systemd service
- Start WOPI server on port 5001

### Step 4: Update Frontend Configuration

Before deploying the frontend, update the Collabora URL in `app.js`:

```bash
cd ~/collabora-deploy/frontend

# Get the correct editor URL
curl -s http://localhost:9980/hosting/discovery | grep urlsrc | head -1

# Edit app.js and update CONFIG.collaboraServer with the URL above
nano app.js
```

### Step 5: Deploy Frontend

```bash
cd ~/collabora-deploy/deployment
sudo ./deploy-frontend.sh
```

This will:
- Install nginx (if needed)
- Copy frontend files to /var/www/app-exp-frontend
- Configure nginx with the provided config
- Reload nginx

### Step 6: Test the Application

Open your browser and navigate to:

```
https://app-exp.dev.lan
```

Click "Open mydoc.docx" - the document should load in Collabora editor!

## 🔧 Manual Deployment Steps

If you prefer to deploy manually or the scripts don't work, follow these detailed steps:

### A. Deploy Collabora CODE

```bash
# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Stop any existing container
sudo docker stop collabora 2>/dev/null || true
sudo docker rm collabora 2>/dev/null || true

# Pull and run Collabora
sudo docker pull collabora/code

sudo docker run -d \
  --name collabora \
  --restart always \
  -p 9980:9980 \
  -e "domain=app-exp\\.dev\\.lan" \
  -e "username=admin" \
  -e "password=YourSecurePassword" \
  -e "extra_params=--o:ssl.enable=false --o:ssl.termination=true --o:net.frame_ancestors=*" \
  collabora/code

# Wait for it to start (30-60 seconds)
sleep 30

# Verify it's running
sudo docker ps | grep collabora
curl http://localhost:9980/hosting/discovery
```

### B. Deploy Backend (WOPI Server)

```bash
# Install Python dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Create backend directory
sudo mkdir -p /opt/wopi-server/documents
cd /opt/wopi-server

# Copy your files (from your local machine or uploaded location)
# Assuming files are in ~/collabora-deploy/backend
sudo cp ~/collabora-deploy/backend/wopi_server.py .
sudo cp ~/collabora-deploy/backend/requirements.txt .
sudo cp ~/collabora-deploy/backend/documents/mydoc.docx ./documents/

# Create virtual environment
sudo python3 -m venv venv
sudo ./venv/bin/pip install -r requirements.txt

# Create systemd service
sudo nano /etc/systemd/system/wopi-server.service
```

Add this content to the service file:

```ini
[Unit]
Description=WOPI Server for Collabora CODE
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/wopi-server
Environment="PATH=/opt/wopi-server/venv/bin"
ExecStart=/opt/wopi-server/venv/bin/python /opt/wopi-server/wopi_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Set permissions
sudo chown -R www-data:www-data /opt/wopi-server

# Start service
sudo systemctl daemon-reload
sudo systemctl enable wopi-server
sudo systemctl start wopi-server

# Check status
sudo systemctl status wopi-server

# Test it
curl http://localhost:5001/health
```

### C. Deploy Frontend

```bash
# Install nginx
sudo apt-get install -y nginx

# Create frontend directory
sudo mkdir -p /var/www/app-exp-frontend

# Copy frontend files
sudo cp ~/collabora-deploy/frontend/index.html /var/www/app-exp-frontend/
sudo cp ~/collabora-deploy/frontend/app.js /var/www/app-exp-frontend/
sudo cp ~/collabora-deploy/frontend/styles.css /var/www/app-exp-frontend/

# Set permissions
sudo chown -R www-data:www-data /var/www/app-exp-frontend
sudo chmod 755 /var/www/app-exp-frontend
sudo chmod 644 /var/www/app-exp-frontend/*
```

### D. Configure Nginx

```bash
# Copy nginx configuration
sudo cp ~/collabora-deploy/deployment/nginx-app-exp.conf /etc/nginx/sites-available/app-exp

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable your site
sudo ln -s /etc/nginx/sites-available/app-exp /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## 🔍 Verification & Testing

### 1. Check All Services

```bash
# Check Collabora
sudo docker ps | grep collabora
curl http://localhost:9980/hosting/discovery

# Check WOPI server
sudo systemctl status wopi-server
curl http://localhost:5001/health

# Check nginx
sudo systemctl status nginx
sudo nginx -t
```

### 2. Test Each Component

```bash
# Test WOPI file info
curl http://localhost:5001/wopi/files/mydoc

# Test through nginx
curl -k https://app-exp.dev.lan/wopi/files/mydoc

# Check Collabora discovery
curl -k https://app-exp.dev.lan/hosting/discovery
```

### 3. Browser Test

1. Open: `https://app-exp.dev.lan`
2. Click "Open mydoc.docx"
3. Document should load in editor

## 📊 Monitoring & Logs

### View Logs

```bash
# Collabora logs
sudo docker logs -f collabora

# WOPI server logs
sudo journalctl -u wopi-server -f

# Nginx access logs
sudo tail -f /var/log/nginx/app-exp-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/app-exp-error.log
```

### Service Management

```bash
# Restart services
sudo systemctl restart wopi-server
sudo systemctl restart nginx
sudo docker restart collabora

# Stop services
sudo systemctl stop wopi-server
sudo systemctl stop nginx
sudo docker stop collabora

# Check status
sudo systemctl status wopi-server
sudo systemctl status nginx
sudo docker ps
```

## 🐛 Troubleshooting

### Issue: Document doesn't load

**Check browser console for errors:**
- F12 → Console tab
- Look for CORS, CSP, or connection errors

**Verify WOPI server:**
```bash
curl http://localhost:5001/wopi/files/mydoc
```
Should return JSON with file info.

**Check Collabora logs:**
```bash
sudo docker logs collabora | grep -i error
```

### Issue: "Unauthorized WOPI host"

**Solution:** Restart Collabora with correct domain:
```bash
sudo docker restart collabora
sudo docker logs collabora | grep "Adding trusted WOPI host"
```

You should see: `Adding trusted WOPI host: [app-exp.dev.lan]`

### Issue: Nginx 502 Bad Gateway

**Check if services are running:**
```bash
sudo systemctl status wopi-server
sudo docker ps | grep collabora
sudo netstat -tlnp | grep -E '5001|9980'
```

### Issue: WebSocket connection failed

**Verify nginx config has WebSocket section:**
```bash
sudo nginx -T | grep -A 5 "ws$"
```

Should show WebSocket upgrade headers.

### Issue: Cannot save document

**Check WOPI server logs:**
```bash
sudo journalctl -u wopi-server -f
```

**Verify file permissions:**
```bash
ls -la /opt/wopi-server/documents/
sudo chown www-data:www-data /opt/wopi-server/documents/mydoc.docx
sudo chmod 644 /opt/wopi-server/documents/mydoc.docx
```

## 🔒 Security Considerations

### For Production

1. **Change default passwords:**
   - Edit `setup-collabora.sh` and change `ADMIN_PASSWORD`

2. **Add authentication to WOPI:**
   - Implement proper access token validation in `wopi_server.py`
   - Use JWT tokens instead of static tokens

3. **Use real SSL certificates:**
   - Replace self-signed certs with Let's Encrypt or commercial certs

4. **Restrict access:**
   - Add firewall rules
   - Limit access to specific IPs if needed

5. **Enable logging:**
   - Configure proper log rotation
   - Monitor for suspicious activity

## 📝 Configuration

### Update Server Domain

If you need to change the domain, update these files:

1. **frontend/app.js:**
   ```javascript
   serverDomain: "https://your-domain.com"
   wopiBase: "https://your-domain.com/wopi/files"
   collaboraServer: "https://your-domain.com/browser/.../cool.html"
   ```

2. **deployment/nginx-app-exp.conf:**
   ```nginx
   server_name your-domain.com;
   ```

3. **deployment/setup-collabora.sh:**
   ```bash
   DOMAIN="your-domain\\.com"
   ```

### Add More Documents

1. Copy .docx files to `/opt/wopi-server/documents/`
2. Update `frontend/app.js` CONFIG.fileId to match filename (without .docx)
3. Ensure proper permissions: `sudo chown www-data:www-data filename.docx`

## 🎓 Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────────────────────────┐
│           Nginx (443)               │
│  ┌──────────┬─────────┬──────────┐ │
│  │ Frontend │  WOPI   │Collabora │ │
│  │  (/)     │ (/wopi/)│(/browser)│ │
│  └────┬─────┴────┬────┴─────┬────┘ │
└───────┼──────────┼──────────┼──────┘
        │          │          │
        │          ▼          ▼
        │   ┌───────────┐ ┌──────────────┐
        │   │WOPI Server│ │ Collabora    │
        │   │ (5001)    │ │ Docker(9980) │
        │   └───────────┘ └──────────────┘
        │
        ▼
   ┌──────────────┐
   │ Static Files │
   │ (Frontend)   │
   └──────────────┘
```

## 📚 Additional Resources

- [WOPI Protocol Documentation](https://wopi.readthedocs.io/)
- [Collabora Online Documentation](https://sdk.collaboraonline.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)

## 🆘 Support

If you encounter issues:

1. Check all logs (see Monitoring & Logs section)
2. Verify all services are running
3. Test each component individually
4. Review the Troubleshooting section

## 📄 License

This project is for educational and development purposes.

---

**Last Updated:** 2025-11-06
