# 🚀 Deployment Checklist

Follow this checklist to deploy the complete Collabora CODE integration.

## ✅ Pre-Deployment

- [ ] Server accessible via SSH
- [ ] Domain `app-exp.dev.lan` configured and accessible
- [ ] SSL certificates available at:
  - `/etc/ssl/certs/app-exp-dev/cert.pem`
  - `/etc/ssl/private/app-exp-dev/key.pem`
- [ ] Root/sudo access to the server
- [ ] All project files ready on local machine

## 📦 Step 1: Copy Files to Server

```bash
# On your local machine, from the Coll-Test directory:

# Create deployment directory on server
ssh user@app-exp.dev.lan "mkdir -p ~/collabora-deploy"

# Copy all files
scp -r backend frontend deployment user@app-exp.dev.lan:~/collabora-deploy/

# Verify files copied
ssh user@app-exp.dev.lan "ls -la ~/collabora-deploy/"
```

**Checklist:**
- [ ] backend/ directory copied
- [ ] frontend/ directory copied
- [ ] deployment/ directory copied
- [ ] mydoc.docx exists in backend/documents/

---

## 🐳 Step 2: Deploy Collabora CODE

```bash
# SSH into server
ssh user@app-exp.dev.lan

cd ~/collabora-deploy/deployment

# Make scripts executable
chmod +x *.sh

# Optional: Edit setup-collabora.sh to change admin password
nano setup-collabora.sh
# Change ADMIN_PASSWORD="SecurePassword123" to your password

# Run Collabora setup
sudo ./setup-collabora.sh
```

**Expected Output:**
```
✓ Docker is already installed (or installed)
✓ Collabora CODE container started
✓ Discovery endpoint is accessible
```

**Checklist:**
- [ ] Docker installed
- [ ] Collabora container running (`docker ps | grep collabora`)
- [ ] Discovery endpoint accessible (`curl http://localhost:9980/hosting/discovery`)
- [ ] Editor URL noted (shown at end of script)

**Save this information:**
```
Editor URL: _______________________________________
Admin Password: ____________________________________
```

---

## 🔧 Step 3: Deploy Backend (WOPI Server)

```bash
# Still on the server, from ~/collabora-deploy/deployment

cd ~/collabora-deploy/backend
sudo ../deployment/deploy-backend.sh
```

**Expected Output:**
```
✓ Python and dependencies installed
✓ Virtual environment created
✓ WOPI server service started
✓ WOPI server is responding on port 5001
```

**Checklist:**
- [ ] Python 3 installed
- [ ] Flask and dependencies installed
- [ ] Service created (`systemctl status wopi-server`)
- [ ] Service running and enabled
- [ ] Health check passes (`curl http://localhost:5001/health`)

**Verify:**
```bash
# Should return JSON
curl http://localhost:5001/wopi/files/mydoc

# Should show service running
sudo systemctl status wopi-server
```

---

## 🎨 Step 4: Update Frontend Configuration

**IMPORTANT:** Before deploying frontend, update the Collabora URL.

```bash
cd ~/collabora-deploy/frontend

# Get the editor URL from Collabora
curl -s http://localhost:9980/hosting/discovery | grep urlsrc | head -1

# You'll see something like:
# urlsrc="https://app-exp.dev.lan/browser/e808afa229/cool.html"

# Edit app.js
nano app.js

# Update line 17 (CONFIG.collaboraServer) with the URL above
# collaboraServer: "https://app-exp.dev.lan/browser/YOUR_HASH_HERE/cool.html"
```

**Checklist:**
- [ ] Got editor URL from discovery endpoint
- [ ] Updated app.js CONFIG.collaboraServer
- [ ] Saved app.js

---

## 🌐 Step 5: Deploy Frontend

```bash
cd ~/collabora-deploy/deployment
sudo ./deploy-frontend.sh
```

**Expected Output:**
```
✓ nginx is already installed (or installed)
Frontend files copied successfully
✓ Nginx configuration is valid
```

**Checklist:**
- [ ] Nginx installed
- [ ] Frontend files copied to `/var/www/app-exp-frontend`
- [ ] Nginx configuration updated
- [ ] Nginx configuration valid (`sudo nginx -t`)
- [ ] Nginx reloaded

**Verify:**
```bash
# Check nginx status
sudo systemctl status nginx

# Check files exist
ls -la /var/www/app-exp-frontend/

# Should show: index.html, app.js, styles.css
```

---

## 🧪 Step 6: Test the Application

### A. Test Individual Components

```bash
# 1. Test WOPI server
curl http://localhost:5001/wopi/files/mydoc
# Should return JSON with file info

# 2. Test WOPI through nginx
curl -k https://app-exp.dev.lan/wopi/files/mydoc
# Should return same JSON

# 3. Test Collabora discovery
curl -k https://app-exp.dev.lan/hosting/discovery
# Should return XML with capabilities

# 4. Test frontend access
curl -k https://app-exp.dev.lan/
# Should return HTML
```

**Checklist:**
- [ ] WOPI server responds on localhost:5001
- [ ] WOPI server responds through nginx
- [ ] Collabora discovery responds
- [ ] Frontend page loads

### B. Test in Browser

1. Open browser
2. Navigate to: `https://app-exp.dev.lan`
3. You should see the frontend page
4. Click "Open mydoc.docx" button
5. Document should load in Collabora editor

**Checklist:**
- [ ] Frontend page loads
- [ ] Page has "Open mydoc.docx" button
- [ ] Clicking button shows editor iframe
- [ ] Document loads in editor
- [ ] Can edit document
- [ ] Changes save (edit something and reload page)

---

## 📊 Step 7: Verify All Services

```bash
# Check all services are running and enabled
sudo systemctl status wopi-server
sudo systemctl status nginx
sudo docker ps | grep collabora

# Check all services start on boot
sudo systemctl is-enabled wopi-server
sudo systemctl is-enabled nginx
sudo docker inspect collabora | grep -i restart
```

**Checklist:**
- [ ] wopi-server: active (running)
- [ ] nginx: active (running)
- [ ] collabora: Up
- [ ] wopi-server: enabled
- [ ] nginx: enabled
- [ ] collabora: restart policy = always

---

## 🔍 Step 8: Check Logs (Optional but Recommended)

```bash
# Check for errors in logs
sudo journalctl -u wopi-server --since "10 minutes ago" | grep -i error
sudo tail -50 /var/log/nginx/app-exp-error.log
sudo docker logs --tail 50 collabora | grep -i error
```

**Checklist:**
- [ ] No critical errors in wopi-server logs
- [ ] No critical errors in nginx logs
- [ ] No critical errors in Collabora logs

---

## ✅ Final Verification

Open browser and test the complete flow:

1. **Go to:** `https://app-exp.dev.lan`
2. **See:** Clean frontend page with "Open mydoc.docx" button
3. **Click:** "Open mydoc.docx"
4. **Wait:** 5-10 seconds for editor to load
5. **See:** Collabora editor with document content
6. **Edit:** Make a change to the document
7. **Wait:** Document should auto-save
8. **Close:** Click "Close Document"
9. **Re-open:** Click "Open mydoc.docx" again
10. **Verify:** Your changes are still there

**Final Checklist:**
- [ ] Page loads without SSL warnings (or with expected self-signed warning)
- [ ] Button works
- [ ] Editor loads successfully
- [ ] Document displays correctly
- [ ] Can edit document
- [ ] Changes persist after closing/reopening

---

## 🎉 Deployment Complete!

If all items are checked, your deployment is successful!

### Access Points

- **Frontend:** https://app-exp.dev.lan
- **Collabora Admin:** https://app-exp.dev.lan/browser/dist/admin/admin.html
  - Username: admin
  - Password: (the one you set in setup-collabora.sh)

### Useful Commands

```bash
# Restart all services
sudo systemctl restart wopi-server nginx
sudo docker restart collabora

# View logs
sudo journalctl -u wopi-server -f
sudo tail -f /var/log/nginx/app-exp-error.log
sudo docker logs -f collabora

# Check status
sudo systemctl status wopi-server nginx
sudo docker ps
```

---

## 🐛 If Something Went Wrong

See the **Troubleshooting** section in README.md

Common issues:
- **Document doesn't load:** Check browser console (F12)
- **502 errors:** Check if wopi-server is running
- **WebSocket errors:** Verify nginx config
- **Unauthorized WOPI host:** Restart Collabora container

For detailed debugging, check all logs:
```bash
sudo journalctl -u wopi-server --since "1 hour ago"
sudo tail -100 /var/log/nginx/app-exp-error.log
sudo docker logs collabora
```

---

## 📝 Notes

**Date Deployed:** _______________

**Server:** app-exp.dev.lan

**Services:**
- Collabora: Port 9980
- WOPI Server: Port 5001
- Nginx: Port 443 (HTTPS)

**Passwords to Remember:**
- Collabora Admin: _______________

---

**Deployment completed successfully!** ✅
