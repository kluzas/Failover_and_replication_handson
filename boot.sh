#!/bin/bash

# This script is run by Raspberry Pi Imager on first boot.
# Its purpose is to set up and enable our main first_boot_setup.service.

echo "Running boot.sh from Raspberry Pi Imager..."

# Copy the main setup script to /home/pi/
# The Imager places files in /boot, so we need to move them.
# Ensure /home/pi exists and is writable.
if [ -f /boot/first_boot_setup.sh ]; then
    cp /boot/first_boot_setup.sh /home/pi/first_boot_setup.sh
    chmod +x /home/pi/first_boot_setup.sh
    chown pi:pi /home/pi/first_boot_setup.sh
    echo "Copied first_boot_setup.sh to /home/pi/"
else
    echo "Error: /boot/first_boot_setup.sh not found!"
fi

# Copy the systemd service file to /etc/systemd/system/
if [ -f /boot/first_boot_setup.service ]; then
    cp /boot/first_boot_setup.service /etc/systemd/system/first_boot_setup.service
    echo "Copied first_boot_setup.service to /etc/systemd/system/"
else
    echo "Error: /boot/first_boot_setup.service not found!"
fi

# Copy the photo_app directory to /home/pi/
if [ -d /boot/photo_app ]; then
    cp -r /boot/photo_app /home/pi/
    chown -R pi:pi /home/pi/photo_app
    echo "Copied photo_app to /home/pi/"
else
    echo "Error: /boot/photo_app not found!"
fi

# Reload systemd to pick up the new service
systemctl daemon-reload
echo "Systemd daemon reloaded."

# Enable and start the first_boot_setup service
systemctl enable first_boot_setup.service
echo "first_boot_setup.service enabled."
systemctl start first_boot_setup.service
echo "first_boot_setup.service started."

echo "boot.sh finished."
