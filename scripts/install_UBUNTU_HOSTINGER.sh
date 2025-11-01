#!/bin/bash

## Installation script for pisignage-server on Ubuntu (Hostinger VPS)
## This script installs MongoDB, Node.js, ffmpeg, ImageMagick, and sets up pisignage-server
##
## Repository Configuration:
## The script uses your forked GitHub repository. To use a different repository,
## set environment variables before running:
##   export GITHUB_USER="your-username"
##   export GITHUB_REPO="your-repo-name"
##   sudo ./install_UBUNTU_HOSTINGER.sh
##
## Private Repository Support:
## - For public repos: works automatically
## - For private repos via HTTPS: export GITHUB_TOKEN="your_github_token"
## - For private repos via SSH: configure SSH keys (ssh-keygen) or set GITHUB_SSH_URL

set -e  # Exit on error

echo "=========================================="
echo "piSignage Server Installation for Ubuntu"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

INSTALL_DIR="/opt"
APP_DIR="$INSTALL_DIR/pisignage-server"
MEDIA_DIR="$INSTALL_DIR/media"
DB_DIR="/data/db"
NODE_VERSION="18.x"  # LTS version

echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Update system packages
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y curl wget gnupg2 lsb-release

# Install MongoDB
echo -e "${YELLOW}[2/8] Installing MongoDB...${NC}"
if ! command -v mongod &> /dev/null; then
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
    
    # Detect Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs)
    CODENAME=$(lsb_release -cs)
    
    # Map unsupported Ubuntu versions to supported LTS versions
    # MongoDB 6.0 supports: focal (20.04), jammy (22.04)
    # For newer versions (noble/24.04, trixie/24.10, etc.), use jammy as it's more stable
    case "$CODENAME" in
        focal|jammy)
            MONGODB_CODENAME="$CODENAME"
            ;;
        # Ubuntu 24.04 (noble), 24.10 (trixie) and other versions -> use jammy (22.04 LTS)
        noble|trixie|*)
            echo -e "${YELLOW}Ubuntu ${CODENAME} (${UBUNTU_VERSION}) detected.${NC}"
            echo -e "${YELLOW}Using jammy (22.04 LTS) repository for MongoDB compatibility...${NC}"
            MONGODB_CODENAME="jammy"
            ;;
    esac
    
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${MONGODB_CODENAME}/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    if apt-get update -y && apt-get install -y mongodb-org; then
        echo -e "${GREEN}MongoDB installation successful${NC}"
    else
        echo -e "${RED}MongoDB installation failed. Please check your repository configuration.${NC}"
        exit 1
    fi
    
    # Create MongoDB data directory
    if [ ! -d "$DB_DIR" ]; then
        mkdir -p "$DB_DIR"
    fi
    
    # Set permissions
    chown -R mongodb:mongodb /data/db
    chmod -R 755 /data/
    
    # Start and enable MongoDB
    systemctl start mongod
    systemctl enable mongod
    
    echo -e "${GREEN}MongoDB installed successfully${NC}"
else
    echo -e "${GREEN}MongoDB is already installed${NC}"
fi

# Install Node.js
echo -e "${YELLOW}[3/8] Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
    apt-get install -y nodejs
    
    # Verify installation
    NODE_VERSION_INSTALLED=$(node -v)
    echo -e "${GREEN}Node.js $NODE_VERSION_INSTALLED installed successfully${NC}"
else
    INSTALLED_VERSION=$(node -v)
    echo -e "${GREEN}Node.js $INSTALLED_VERSION is already installed${NC}"
fi

# Install Git
echo -e "${YELLOW}[4/8] Installing Git...${NC}"
if ! command -v git &> /dev/null; then
    apt-get install -y git
    echo -e "${GREEN}Git installed successfully${NC}"
else
    echo -e "${GREEN}Git is already installed${NC}"
fi

# Install ffmpeg
echo -e "${YELLOW}[5/8] Installing ffmpeg...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    apt-get install -y ffmpeg
    echo -e "${GREEN}ffmpeg installed successfully${NC}"
else
    echo -e "${GREEN}ffmpeg is already installed${NC}"
fi

# Install ImageMagick
echo -e "${YELLOW}[6/8] Installing ImageMagick...${NC}"
if ! command -v convert &> /dev/null; then
    apt-get install -y imagemagick
    echo -e "${GREEN}ImageMagick installed successfully${NC}"
else
    echo -e "${GREEN}ImageMagick is already installed${NC}"
fi

# Clone or update pisignage-server
echo -e "${YELLOW}[7/8] Setting up piSignage Server...${NC}"

# GitHub repository configuration
# Update these variables with your repository information or set via environment variables
GITHUB_USER="${GITHUB_USER:-github-nourdine-dahmani}"
GITHUB_REPO="${GITHUB_REPO:-pisignage-server}"

# Repository URL configuration
# For public repos: use HTTPS
# For private repos: use SSH (requires SSH keys) or HTTPS with token
# Priority: GITHUB_TOKEN > SSH > HTTPS
if [ -n "$GITHUB_TOKEN" ]; then
    # Use token for private repos via HTTPS
    REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git"
    echo -e "${GREEN}Using GitHub token for authentication${NC}"
elif [ -n "$GITHUB_SSH_URL" ]; then
    # Use custom SSH URL if provided
    REPO_URL="$GITHUB_SSH_URL"
    echo -e "${GREEN}Using SSH URL for repository access${NC}"
elif [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then
    # Try SSH if keys exist (works for both public and private repos)
    REPO_URL="git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git"
    echo -e "${GREEN}Using SSH for repository access${NC}"
else
    # Default to HTTPS (only works for public repos)
    REPO_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"
    echo -e "${YELLOW}Using HTTPS (public repository required)${NC}"
    echo -e "${YELLOW}For private repos, set GITHUB_TOKEN or configure SSH keys${NC}"
fi

if [ -d "$APP_DIR" ]; then
    echo "Directory exists, updating..."
    cd "$APP_DIR"
    git pull origin master || echo "Warning: Could not pull latest changes"
else
    echo "Cloning repository from ${REPO_URL}..."
    cd "$INSTALL_DIR"
    if git clone "$REPO_URL" pisignage-server; then
        echo -e "${GREEN}Repository cloned successfully${NC}"
    else
        echo -e "${RED}Failed to clone repository${NC}"
        echo -e "${YELLOW}If using a private repository, you need to:${NC}"
        echo "  1. Set GITHUB_TOKEN environment variable: export GITHUB_TOKEN=your_token"
        echo "  2. Or configure SSH keys: ssh-keygen -t ed25519 -C 'your_email@example.com'"
        echo "  3. Or make the repository public"
        exit 1
    fi
    cd "$APP_DIR"
fi

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install --production

# Determine the user to run the service
if [ -n "$SUDO_USER" ]; then
    SERVICE_USER="$SUDO_USER"
else
    SERVICE_USER=$(whoami)
fi

# Create media directories (one level up from app directory as per config)
echo "Creating media directories..."
MEDIA_PARENT_DIR=$(dirname "$APP_DIR")
MEDIA_DIR="$MEDIA_PARENT_DIR/media"

if [ ! -d "$MEDIA_DIR" ]; then
    mkdir -p "$MEDIA_DIR"
fi

if [ ! -d "$MEDIA_DIR/_thumbnails" ]; then
    mkdir -p "$MEDIA_DIR/_thumbnails"
fi

if [ ! -d "$MEDIA_DIR/_logs" ]; then
    mkdir -p "$MEDIA_DIR/_logs"
fi

# Set permissions
chmod -R 755 "$MEDIA_DIR"
chown -R $SERVICE_USER:$SERVICE_USER "$MEDIA_DIR" 2>/dev/null || chown -R $(whoami):$(whoami) "$MEDIA_DIR"

echo -e "${GREEN}Media directories created at $MEDIA_DIR${NC}"

# Create systemd service
echo -e "${YELLOW}[8/8] Creating systemd service...${NC}"
SERVICE_FILE="/etc/systemd/system/pisignage.service"

# Get user's home directory
USER_HOME=$(eval echo ~$SERVICE_USER)

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=piSignage Player - Server Software
After=network.target mongod.service
Requires=mongod.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
Restart=always
RestartSec=10
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/server.js
StandardOutput=journal
StandardError=journal
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=HOME=$USER_HOME

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

echo ""
echo -e "${GREEN}=========================================="
echo "Installation completed successfully!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Start the service:"
echo "   sudo systemctl start pisignage"
echo ""
echo "2. Enable auto-start on boot:"
echo "   sudo systemctl enable pisignage"
echo ""
echo "3. Check service status:"
echo "   sudo systemctl status pisignage"
echo ""
echo "4. View logs:"
echo "   sudo journalctl -u pisignage.service -f"
echo ""
echo "5. Access the application at:"
echo "   http://your-server-ip:3000"
echo ""
echo "Default credentials:"
echo "   Username: pi"
echo "   Password: pi"
echo ""
echo -e "${YELLOW}Important: Change the default password after first login!${NC}"
echo ""

