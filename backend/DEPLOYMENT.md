# Deployment Guide — AI Udaan Backend (Ubuntu VPS / Hostinger)

**Production URL:** `https://backend.aiudaanbootcamp.com`  
**Stack:** Node.js 18 + Express + Socket.IO + PM2 + Nginx + Let's Encrypt

---

## 1. Install Node.js 18

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node -v   # should print v18.x.x
```

---

## 2. Install PM2 globally

```bash
npm install -g pm2
```

---

## 3. Clone & Configure

```bash
cd /var/www
git clone <your-repo-url> ai-udaan-backend
cd ai-udaan-backend/backend

# Copy and fill in environment variables
cp .env.example .env
nano .env
# Set: NODE_ENV=production, PORT=9000, all Moodle tokens, SMTP, Razorpay live keys

# Install production dependencies only
npm install --production

# Create logs directory
mkdir -p logs
```

---

## 4. Start with PM2

```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup   # follow the printed command to enable auto-start on reboot
```

---

## 5. Configure Nginx

```bash
# Copy the example config
sudo cp nginx.conf.example /etc/nginx/sites-available/ai-udaan
sudo ln -s /etc/nginx/sites-available/ai-udaan /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

---

## 6. SSL with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d backend.aiudaanbootcamp.com
# Certbot will auto-patch your nginx config with SSL certs
```

---

## 7. Firewall

```bash
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw status
```

---

## 8. Verify Deployment

```bash
# Health check
curl https://backend.aiudaanbootcamp.com/api/health
# Expected: {"status":"OK","timestamp":"..."}

# Check PM2 status
pm2 status

# View logs
pm2 logs ai-udaan-backend --lines 50
```

---

## Useful PM2 Commands

```bash
pm2 status                        # All process status
pm2 logs ai-udaan-backend         # Live logs
pm2 logs ai-udaan-backend --err   # Error logs only
pm2 reload ai-udaan-backend       # Zero-downtime reload (use after .env changes)
pm2 restart ai-udaan-backend      # Full restart
pm2 monit                         # CPU/memory dashboard
pm2 flush                         # Clear log files
```

---

## Updating the App

```bash
cd /var/www/ai-udaan-backend/backend
git pull origin main
npm install --production
pm2 reload ai-udaan-backend   # Zero-downtime reload
```

---

## Environment Variable Reference

| Key | Required | Description |
|-----|----------|-------------|
| `PORT` | ✅ | Must be `9000` |
| `NODE_ENV` | ✅ | Must be `production` |
| `BASE_URL` | ✅ | `https://backend.aiudaanbootcamp.com` |
| `CORS_ORIGIN` | ✅ | `*` (Flutter mobile doesn't send Origin) |
| `JWT_SECRET` | ✅ | Run `openssl rand -base64 32` to generate |
| `JWT_EXPIRES_IN` | ✅ | `7d` |
| `MOODLE_URL` | ✅ | `https://moodle.aiudaanbootcamp.com` |
| `MOODLE_TOKEN` | ✅ | Admin token (main service) |
| `MOODLE_COURSE_TOKEN` | ✅ | Same as MOODLE_TOKEN |
| `MOODLE_CREATE_USER_TOKEN` | ✅ | Token for user creation service |
| `MOODLE_ENROL_TOKEN` | ✅ | Token for enrollment service |
| `MOODLE_SERVICE_NAME` | ✅ | `moodle_mobile_app` |
| `SMTP_HOST` | ✅ | `smtp.zoho.in` |
| `SMTP_PORT` | ✅ | `465` |
| `SMTP_SECURE` | ✅ | `true` |
| `SMTP_USER` | ✅ | Zoho email address |
| `SMTP_PASS` | ✅ | Zoho email password |
| `RAZORPAY_KEY_ID` | ✅ | Live key (starts with `rzp_live_`) |
| `RAZORPAY_KEY_SECRET` | ✅ | Live secret |

---

## Troubleshooting

**502 Bad Gateway from Nginx**  
→ PM2 app is not running. Run `pm2 status` and `pm2 logs`.

**Connection refused on port 9000**  
→ Server crashed. Run `pm2 restart ai-udaan-backend`.

**Moodle API errors after deploy**  
→ Tokens may have expired. Regenerate from Moodle Admin → Manage Tokens.

**Email not sending**  
→ Check SMTP credentials with `pm2 logs --err`. Zoho may require app-specific password.
