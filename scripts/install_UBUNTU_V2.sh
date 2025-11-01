## script to install mongodb , node.js , pisignage-server
## Works with Ubuntu and Debian
## for more info http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

DBDIR="/data/db"

echo " installing mongodb"

# Clean up any existing MongoDB repository files FIRST
echo "Cleaning up existing MongoDB repositories..."
sudo rm -f /etc/apt/sources.list.d/mongodb-org*.list
sudo rm -f /etc/apt/sources.list.d/mongodb*.list
sudo sed -i '/mongodb/d' /etc/apt/sources.list 2>/dev/null || true
sudo apt-get clean

# Install essential packages
sudo apt-get update -y
sudo apt-get install -y curl wget gnupg2 lsb-release

# Install MongoDB using modern method (no deprecated apt-key)
if ! command -v mongod &> /dev/null; then
    # Import MongoDB GPG key using modern method
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
    
    # Detect distribution and codename
    CODENAME=$(lsb_release -cs)
    DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    
    # Map unsupported codenames to supported ones
    # MongoDB 6.0 supports: focal (20.04), jammy (22.04)
    # For Debian Trixie and other newer versions, use jammy
    case "$CODENAME" in
        focal|jammy)
            MONGODB_CODENAME="$CODENAME"
            ;;
        # Debian Trixie, Ubuntu Noble/Trixie and other versions -> use jammy (22.04 LTS)
        trixie|noble|*)
            echo "Detected ${DISTRO} ${CODENAME}"
            echo "Using jammy (22.04 LTS) repository for MongoDB compatibility..."
            MONGODB_CODENAME="jammy"
            ;;
    esac
    
    # Add MongoDB repository (works for both Ubuntu and Debian when using Ubuntu codename)
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${MONGODB_CODENAME}/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    sudo apt-get update -y
    sudo apt-get install -y mongodb-org || {
        echo "ERROR: MongoDB installation failed!"
        exit 1
    }
    
    echo "MongoDB installed successfully"
else
    echo "MongoDB is already installed"
fi

# check /data/db directory present if not create
if [ ! -d "$DBDIR" ];then
	sudo mkdir -p /data/db
fi
# Set proper permissions (mongodb user if it exists, otherwise root)
if id "mongodb" &>/dev/null; then
    sudo chown -R mongodb:mongodb /data/db
fi
sudo chmod -R 755 /data/

# From https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager
echo " installing Node.js"
if ! command -v node &> /dev/null; then
    echo "Node.js not found, installing from NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js is already installed: $(node -v)"
    echo "Skipping NodeSource setup. If you need to reinstall, remove Node.js first."
fi

# Verify Node.js and npm installation
if command -v node &> /dev/null; then
    echo "Node.js version: $(node -v)"
else
    echo "ERROR: Node.js installation failed!"
    exit 1
fi

if command -v npm &> /dev/null; then
    echo "npm version: $(npm -v)"
else
    echo "WARNING: npm not found after Node.js installation."
    echo "This can happen if Node.js was installed from Debian repos."
    echo "Installing npm separately..."
    sudo apt-get update -y
    sudo apt-get install -y npm || {
        echo "ERROR: Failed to install npm via apt."
        echo "Trying alternative: installing npm via NodeSource..."
        # NodeSource setup should install npm, but if it didn't, try corepack
        if command -v node &> /dev/null; then
            echo "Enabling corepack (Node.js built-in package manager)..."
            sudo corepack enable || {
                echo "ERROR: All npm installation methods failed!"
                echo "Node.js version: $(node -v)"
                exit 1
            }
            echo "npm should now be available via corepack"
        else
            echo "ERROR: Node.js not found. Cannot install npm."
            exit 1
        fi
    }
    # Verify npm is now available
    if command -v npm &> /dev/null; then
        echo "npm version: $(npm -v)"
    else
        echo "ERROR: npm still not found after installation attempts!"
        exit 1
    fi
fi


echo "installing pisignage-server"
git clone https://github.com/colloqi/pisignage-server
cd pisignage-server
npm install

#create media and thumbnail directory
cd ..
mkdir media
sudo chmod 755 -R ./media
