# Installation Guide for Hostinger VPS (Ubuntu)

This guide will help you install piSignage Server on your Hostinger VPS running Ubuntu.

## Quick Start (5 minutes)

For experienced users who want to get up and running quickly:

```bash
# 1. SSH into your VPS
ssh root@your-vps-ip

# 2. Download and run installation script
cd ~
# For PUBLIC repositories: works automatically
# For PRIVATE repositories: you'll need to provide authentication (see detailed guide below)
wget https://raw.githubusercontent.com/github-nourdine-dahmani/pisignage-server/master/scripts/install_UBUNTU_HOSTINGER.sh
chmod +x install_UBUNTU_HOSTINGER.sh

# If using a private repo, set authentication first:
# export GITHUB_TOKEN="your_token"  # OR configure SSH keys
sudo ./install_UBUNTU_HOSTINGER.sh

# 3. Start services
sudo systemctl start mongod
sudo systemctl start pisignage
sudo systemctl enable pisignage

# 4. Access at http://your-vps-ip:3000 (default: pi/pi)
```

**Important:** Change default password after first login! See full guide below for detailed instructions, troubleshooting, and security recommendations.

---

## Prerequisites

- Ubuntu 18.04 or higher (20.04/22.04 recommended)
- Root or sudo access
- At least 2GB RAM and 30GB disk space
- Open ports: 3000 (HTTP) - you may need to configure this in Hostinger's firewall

## Step-by-Step Installation

### 1. Connect to Your VPS

SSH into your Hostinger VPS:
```bash
ssh root@your-vps-ip
# or
ssh your-username@your-vps-ip
```

### 2. Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Run the Installation Script

You have two options:

#### Option A: Use the Automated Installation Script (Recommended)

**Note:** This script uses the forked repository at `github-nourdine-dahmani/pisignage-server`. If you're using this from your own fork, update the GitHub URL below with your username and repository name.

```bash
cd ~
# Download the installation script from your GitHub repository
# For PUBLIC repos: works automatically
wget https://raw.githubusercontent.com/github-nourdine-dahmani/pisignage-server/master/scripts/install_UBUNTU_HOSTINGER.sh

# Or if you've already cloned the repo:
# cd pisignage-server
# chmod +x scripts/install_UBUNTU_HOSTINGER.sh
# sudo ./scripts/install_UBUNTU_HOSTINGER.sh

chmod +x install_UBUNTU_HOSTINGER.sh
sudo ./install_UBUNTU_HOSTINGER.sh
```

The installation script will automatically clone the code from the configured GitHub repository. 

**For Private Repositories:**

⚠️ **Important**: If your repository is private, the initial `wget` command to download the installation script will fail because `raw.githubusercontent.com` requires public access. You have two options:

**A. Upload the script manually:**
   - Clone your repo locally
   - Upload `scripts/install_UBUNTU_HOSTINGER.sh` to your VPS via SCP:
     ```bash
     scp scripts/install_UBUNTU_HOSTINGER.sh user@your-vps-ip:~/
     ```
   - Then SSH into your VPS and run it

**B. Use GitHub token in URL (if you have one):**
   ```bash
   # Download script using token (replace with your token)
   wget --header="Authorization: token ghp_your_token" \
     https://raw.githubusercontent.com/github-nourdine-dahmani/pisignage-server/master/scripts/install_UBUNTU_HOSTINGER.sh
   ```

Then, to clone the repository during installation:

**Option 1: Using GitHub Token (HTTPS)**
```bash
export GITHUB_TOKEN="ghp_your_personal_access_token"
export GITHUB_USER="your-username"
export GITHUB_REPO="your-repo-name"
sudo ./install_UBUNTU_HOSTINGER.sh
```

**Option 2: Using SSH Keys**
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add the public key to your GitHub account (Settings > SSH Keys)
# Then the script will automatically use SSH

export GITHUB_USER="your-username"
export GITHUB_REPO="your-repo-name"
sudo ./install_UBUNTU_HOSTINGER.sh
```

**Option 3: Custom SSH URL**
```bash
export GITHUB_SSH_URL="git@github.com:your-username/your-repo.git"
sudo ./install_UBUNTU_HOSTINGER.sh
```

**For Public Repositories:**
```bash
export GITHUB_USER="your-username"
export GITHUB_REPO="your-repo-name"
sudo ./install_UBUNTU_HOSTINGER.sh
```

#### Option B: Manual Installation

Follow the manual steps below if you prefer to install manually.

### 4. Configure Firewall (if applicable)

If Hostinger has a firewall enabled, allow port 3000:

```bash
# If using UFW
sudo ufw allow 3000/tcp
sudo ufw reload

# If using iptables
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
```

### 5. Start the Service

```bash
# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Start piSignage Server
sudo systemctl start pisignage
sudo systemctl enable pisignage

# Check status
sudo systemctl status pisignage
```

### 6. Access the Application

Open your browser and navigate to:
```
http://your-vps-ip:3000
```

Default credentials:
- Username: `pi`
- Password: `pi`

**Important:** Change the default password immediately after first login via Settings.

### 7. Configuration

1. **Change Default Password**: Go to Settings and change the authentication credentials
2. **Configure Username**: Set your pisignage.com username (not email) in Settings
3. **Upload Licenses**: Upload license files from pisignage.com under Settings
4. **Network Configuration**: The server runs on port 3000 by default

## Service Management

### Start/Stop/Restart Service

```bash
sudo systemctl start pisignage
sudo systemctl stop pisignage
sudo systemctl restart pisignage
```

### View Logs

```bash
# View recent logs
sudo journalctl -u pisignage.service -n 100

# Follow logs in real-time
sudo journalctl -u pisignage.service -f
```

### Check Service Status

```bash
sudo systemctl status pisignage
```

## Troubleshooting

### MongoDB Not Running

```bash
sudo systemctl status mongod
sudo systemctl start mongod
```

### Port Already in Use

If port 3000 is already in use, edit the production config:
```bash
sudo nano /opt/pisignage-server/config/env/production.js
# Change the port number
```

Then restart the service:
```bash
sudo systemctl restart pisignage
```

### Permission Issues

Ensure proper ownership:
```bash
sudo chown -R $USER:$USER /opt/pisignage-server
sudo chown -R mongodb:mongodb /var/lib/mongodb
```

### Check Application Logs

```bash
# Check if media directory exists
ls -la ../media

# Check Node.js version
node -v

# Check MongoDB connection
mongosh --eval "db.adminCommand('ping')"
```

## Directory Structure

After installation:
```
/opt/pisignage-server/     # Application directory
/opt/media/                 # Media files directory
/opt/media/_thumbnails/     # Thumbnails directory
/data/db/                   # MongoDB data directory
/var/log/pisignage.log      # Application logs
```

## Security Recommendations

1. **Change Default Credentials**: Immediately change pi:pi after installation
2. **Setup HTTPS**: Consider setting up Nginx reverse proxy with SSL certificate
3. **Firewall**: Only open necessary ports
4. **Regular Updates**: Keep system and dependencies updated
5. **Backup**: Regularly backup `/opt/pisignage-server` and `/data/db` directories

## Using with Reverse Proxy (Nginx)

For production, consider using Nginx as a reverse proxy:

1. Install Nginx:
```bash
sudo apt install nginx
```

2. Create Nginx configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

3. Setup SSL with Let's Encrypt:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/colloqi/pisignage-server/issues
- Email: support@pisignage.com

