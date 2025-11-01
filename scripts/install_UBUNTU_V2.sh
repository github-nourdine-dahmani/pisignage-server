## script to install mongodb 7.0 , node.js (latest), npm, pisignage-server
## for more info https://www.mongodb.com/docs/manual/installation/

DBDIR="/opt/pisignage/data/db"

echo "Installing prerequisites for MongoDB"
sudo apt-get install -y gnupg curl

echo "Importing MongoDB public GPG key"
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "Detecting Ubuntu version and configuring MongoDB repository"
UBUNTU_VERSION=$(lsb_release -sc)

if [ "$UBUNTU_VERSION" = "jammy" ] || [ "$UBUNTU_VERSION" = "kinetic" ] || [ "$UBUNTU_VERSION" = "lunar" ] || [ "$UBUNTU_VERSION" = "mantic" ]; then
    # Ubuntu 22.04 (jammy) or later
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
elif [ "$UBUNTU_VERSION" = "focal" ]; then
    # Ubuntu 20.04 (focal)
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
else
    echo "Warning: Unsupported Ubuntu version detected ($UBUNTU_VERSION). Using jammy repository as fallback."
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
fi

echo "Refreshing APT repository"
sudo apt-get update

echo "Installing MongoDB 7.0"
sudo apt-get install -y mongodb-org

# check /data/db directory present if not create
if [ ! -d "$DBDIR" ];then
	sudo mkdir -p /opt/pisignage/data/db
fi
#change permission
sudo chmod -R 755 /opt/pisignage/data/

echo "Installing Node.js (latest version)"
sudo apt update
sudo apt install -y nodejs

echo "Installing npm"
sudo apt install -y npm

echo "Installing pisignage-server in /opt"
# Remove existing installation if present
if [ -d "/opt/pisignage/server" ]; then
    echo "Removing existing /opt/pisignage/server directory"
    sudo rm -rf /opt/pisignage/server
fi

# Clone repository into /opt
sudo git clone https://github.com/colloqi/pisignage-server /opt/pisignage/server
cd /opt/pisignage/server
sudo npm install

#create media and thumbnail directory
sudo mkdir -p /opt/pisignage/media
sudo chmod 755 -R /opt/pisignage/server
sudo chmod 755 -R /opt/pisignage/media

