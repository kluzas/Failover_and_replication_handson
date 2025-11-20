#!/bin/bash

# This script runs on first boot to set up the Raspberry Pi for the workshop.

# Log all output to a file
exec > >(tee /var/log/first_boot_setup.log) 2>&1
echo "Starting first boot setup script..."

# --- 1. Update apt cache ---
echo "Updating apt cache..."
sudo apt update -y

# --- 2. Install Nginx ---
echo "Installing Nginx..."
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Create a simple personalized Nginx page
echo "Creating personalized Nginx index.html..."
PI_HOSTNAME=$(hostname)
sudo bash -c "echo '<h1>Hello from $PI_HOSTNAME!</h1>' > /var/www/html/index.html"

# --- 3. Install Cloudflared ---
echo "Installing Cloudflared..."
# Add Cloudflare GPG key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-warp-apt-pubkey.gpg | sudo gpg --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
# Add Cloudflare repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
# Update apt cache again to include Cloudflare repo
sudo apt update -y
# Install cloudflared
sudo apt install cloudflared -y

# --- 4. Install python3-pip ---
echo "Installing python3-pip..."
sudo apt install python3-pip -y

# --- 4a. Install Syncthing ---
echo "Installing Syncthing..."
# Add the release PGP keys:
sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
# Add the "stable" channel to your APT sources:
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
# Update and install syncthing:
sudo apt update -y
sudo apt install syncthing -y

# Enable and start the Syncthing service for the 'pi' user
echo "Enabling Syncthing service for user 'pi'..."
# We need to wait a moment for the user session to be ready
sleep 10
sudo -u pi XDG_RUNTIME_DIR=/run/user/$(id -u pi) systemctl --user enable syncthing.service
sudo -u pi XDG_RUNTIME_DIR=/run/user/$(id -u pi) systemctl --user start syncthing.service

# --- 5. Create a directory for photo uploads ---
echo "Creating photo upload directory..."
PHOTO_UPLOAD_DIR="/home/pi/photos"
sudo mkdir -p "$PHOTO_UPLOAD_DIR"
sudo chown pi:pi "$PHOTO_UPLOAD_DIR" # Ensure the 'pi' user can write to it

# --- 6. Create a directory for the Python app ---
echo "Creating Python app directory..."
PYTHON_APP_DIR="/home/pi/photo_app"
sudo mkdir -p "$PYTHON_APP_DIR"
sudo chown pi:pi "$PYTHON_APP_DIR"

# --- 7. Cloudflared Tunnel Setup ---
echo "Setting up Cloudflared tunnel configuration..."
CLOUDFLARED_DIR="/etc/cloudflared"
sudo mkdir -p "$CLOUDFLARED_DIR"
sudo chown root:root "$CLOUDFLARED_DIR"
sudo chmod 755 "$CLOUDFLARED_DIR"

# Create a placeholder config.yml
# This will be updated manually later with the actual tunnel ID and credentials.
sudo bash -c "cat <<EOF > ${CLOUDFLARED_DIR}/config.yml
tunnel: <YOUR_TUNNEL_UUID>
credentials-file: /etc/cloudflared/<YOUR_TUNNEL_UUID>.json
metrics: 0.0.0.0:2006
logfile: /var/log/cloudflared.log
loglevel: info
warp-routing:
  enabled: true
ingress:
  - hostname: pi-$(hostname | sed 's/pi-//g').my-pi-workshop.com
    service: http://localhost:80
  - service: http://localhost:80
EOF"

# Create systemd service for cloudflared tunnel
echo "Creating systemd service for cloudflared tunnel..."
sudo bash -c "cat <<EOF > /etc/systemd/system/cloudflared-tunnel.service
[Unit]
Description=Cloudflared Tunnel
After=network.target

[Service]
TimeoutStartSec=0
Type=notify
ExecStart=/usr/local/bin/cloudflared tunnel run --config ${CLOUDFLARED_DIR}/config.yml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl enable cloudflared-tunnel.service
# Note: The service will not start successfully until the tunnel is created and authenticated manually.

# --- 8. Python App Setup ---
echo "Copying Python photo app to /home/pi/photo_app..."
# Assuming the photo_app directory is copied to /boot by the Imager
# and then moved to /home/pi/ by boot.sh
# For now, we'll simulate copying from a known location.
# In a real scenario, the Imager would place this in /boot, and boot.sh would move it.
# For the purpose of this script, we'll assume the files are already in /home/pi/photo_app
# as the boot.sh script would have moved them from /boot.

# Create systemd service for the Python app
echo "Creating systemd service for Python photo app..."
sudo bash -c "cat <<EOF > /etc/systemd/system/photo-app.service
[Unit]
Description=Python Photo App
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/photo_app
Environment=UPLOAD_FOLDER=/home/pi/photos
ExecStart=/usr/bin/python3 app.py
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl enable photo-app.service
sudo systemctl start photo-app.service

echo "First boot setup script finished."
# Disable this service so it doesn't run again
sudo systemctl disable first_boot_setup.service
# Remove the service file itself
sudo rm /etc/systemd/system/first_boot_setup.service
# Reload systemd to reflect changes
sudo systemctl daemon-reload

# --- 9. Reboot the system ---
# This is important to ensure all changes take effect, especially for cloudflared and systemd services.
echo "Rebooting system in 5 seconds..."
sleep 5
sudo reboot
