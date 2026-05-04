# Deployment Guide — LMS Backend (Ubuntu VPS)

## Prerequisites
- Ubuntu 20.04+ VPS
- Node.js 18+ (via nvm or apt)
- PM2 (`npm install -g pm2`)
- Nginx
- Domain name with DNS pointing to VPS IP
- Valid Moodle web service configuration (`MOODLE_URL` and tokens in `.env`)

---

## 1. Install Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node -v
```

## 2. Clone & Configure Application

```bash
cd /var/www
git clone <your-repo-url> lms-backend
cd lms-backend

cp .env.example .env
nano .env  # Fill in all values
npm install --production
```

## 3. Setup PM2

```bash
npm install -g pm2
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup  # Follow the output instructions
```

## 4. Configure Nginx

```bash
sudo cp nginx.conf.example /etc/nginx/sites-available/lms
sudo ln -s /etc/nginx/sites-available/lms /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 5. SSL with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 6. Firewall

```bash
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

## 7. Verify

```bash
curl https://your-domain.com/api/health
# Should return: {"status":"OK","timestamp":"..."}
```

## Useful PM2 Commands

```bash
pm2 status          # Check status
pm2 logs            # View logs
pm2 restart all     # Restart
pm2 reload all      # Zero-downtime reload
pm2 monit           # Monitor
```
