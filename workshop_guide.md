# Raspberry Pi High-Availability Web Service Workshop Guide

## Introduction

Welcome to the "From Zero to High-Availability: Building a Resilient Web Service with Raspberry Pi" workshop! In this hands-on session, you will learn fundamental concepts of web infrastructure, networking, and reliability by building a fault-tolerant photo gallery using Raspberry Pis, Nginx, Cloudflare Tunnels, and Syncthing.

**Target Audience:** 12th Grade Students
**Duration:** 4-6 hours (depending on pace)

## Hardware & Software Requirements

*   **Hardware:**
    *   3 Raspberry Pi (4 or 5 recommended)
    *   3 SD Cards (16GB+ recommended)
    *   3 Raspberry Pi Power Supplies
    *   Laptops for students (with SSH client like Terminal/PuTTY/WSL)
    *   SD card reader for laptops
*   **Software:**
    *   Raspberry Pi Imager (download from [raspberrypi.com/software](https://www.raspberrypi.com/software/))
    *   A Cloudflare account with a registered domain (e.g., `my-pi-workshop.com`)
    *   All workshop script files provided (see below)

## Workshop Plan Overview

This workshop is divided into several parts, building complexity step-by-step:

*   **Part 0: Pre-Workshop Preparation (Instructor's Task):** Getting all necessary hardware, software, and accounts ready.
*   **Part 1: Headless Setup & First Connection:** Flashing SD cards with pre-configured OS, Wi-Fi, and SSH.
*   **Part 2: Your First Web Server:** SSHing into the Pi, installing Nginx, and serving a simple personalized web page.
*   **Part 3: Going Public with Cloudflare Tunnel:** Exposing the local Nginx server to the internet using a secure tunnel.
*   **Part 4: A Dynamic Photo App:** Replacing the static page with a simple Python web app for uploading and viewing photos.
*   **Part 5: Demonstrating the Single Point of Failure:** Physically demonstrating the fragility of a single-server setup.
*   **Part 6: Building a Resilient System:** Creating a fault-tolerant system using folder replication (Syncthing) and DNS-level failover (Cloudflare).

---

## Part 0: Pre-Workshop Preparation (Instructor's Task)

**Goal:** Have all necessary hardware, software, and accounts ready to ensure a smooth workshop.

1.  **Hardware Setup:**
    *   Ensure all 3 Raspberry Pis are functional.
    *   Have SD cards, readers, and power supplies for each.
2.  **Software & Accounts:**
    *   Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
    *   Create a [Cloudflare](https://www.cloudflare.com/) account and register a domain name (e.g., `my-pi-workshop.com`). This is crucial for the tunneling and DNS parts.
    *   Ensure you have the Python photo gallery application code and all setup scripts (`first_boot_setup.sh`, `first_boot_setup.service`, `boot.sh`) readily available.
3.  **Network Information:**
    *   Have the workshop's Wi-Fi SSID and password ready.

---

## Part 1: Headless Setup & First Connection

**Goal:** Students will flash an SD card with a pre-configured OS that automatically connects to Wi-Fi and has SSH enabled, allowing "headless" access.

### Instructions for Instructor: Preparing SD Cards with Raspberry Pi Imager

This process ensures that each Raspberry Pi automatically sets up its environment on the first boot, including installing necessary software and configuring services.

**Prerequisites:**

*   **Raspberry Pi Imager:** Download and install the latest version from [raspberrypi.com/software](https://www.raspberrypi.com/software/).
*   **Workshop Files:** Ensure you have the following files ready on your computer:
    *   `first_boot_setup.sh` (the main setup script)
    *   `first_boot_setup.service` (the systemd unit file for the main script)
    *   `boot.sh` (the script to be run by the Imager to install the systemd service)
    *   The `photo_app` directory containing `app.py`, `templates/index.html`, and `requirements.txt`.

**Steps:**

1.  **Open Raspberry Pi Imager:** Launch the application.

2.  **Choose OS:**
    *   Click "CHOOSE OS".
    *   Select "Raspberry Pi OS (other)" -> "Raspberry Pi OS Lite (64-bit)". This provides a minimal, headless installation.

3.  **Choose Storage:**
    *   Click "CHOOSE STORAGE".
    *   Select one of your SD cards. **Be very careful to select the correct device.**

4.  **Configure Advanced Options (Crucial Step):**
    *   Click the "gear" icon (or press `Ctrl+Shift+X` on your keyboard) to open the "OS customisation options".
    *   **General:**
        *   **Set hostname:** This is important for identifying each Pi. For the first Pi, enter `pi-1`. For the second, `pi-2`, and for the third, `pi-3`. (Students will do this uniquely for each Pi).
        *   **Enable SSH:** Check "Enable SSH" and select "Use password authentication". Set a strong, memorable password for the `pi` user.
        *   **Configure wireless LAN:** Check "Configure wireless LAN". Enter the **SSID** (Wi-Fi network name) and **Password** for your workshop Wi-Fi. Select your **Wireless LAN country**.
        *   **Set locale settings:** Choose your **Time zone** and **Keyboard layout**.
    *   **Services:**
        *   **Run first-boot script:** Check this option. Browse and select the `boot.sh` file you prepared. This script will handle moving and enabling your systemd service.
        *   **Add files to OS:** This is where you'll place your setup files.
            *   Click "Add files to OS".
            *   Navigate to where you saved `first_boot_setup.sh`, `first_boot_setup.service`, and the `photo_app` directory. Select all of them.
            *   For the destination path, enter `/boot/`. (The Imager places these files directly into the boot partition, which `boot.sh` will then move).
    *   **Persistent settings:** Select "To always use these options" if you are preparing multiple cards with similar settings, but remember to change the hostname for each card.
    *   Click "SAVE".

5.  **Write to SD Card:**
    *   Review your selections.
    *   Click "WRITE".
    *   Confirm the action when prompted. The Imager will write the OS and your customisations to the SD card. This process can take several minutes.

6.  **Repeat for Each Pi:**
    *   Once the writing is complete, remove the SD card.
    *   Insert the next blank SD card.
    *   Repeat steps 3-5, ensuring you **change the hostname** (e.g., `pi-2`, `pi-3`) for each subsequent SD card.

### After Imaging:

*   Insert the prepared SD cards into your Raspberry Pis.
*   Power on the Raspberry Pis.
*   On first boot, the `boot.sh` script will run, which in turn enables and starts `first_boot_setup.service`. This service will then perform all the installations and configurations defined in `first_boot_setup.sh`.
*   The Pi will reboot once `first_boot_setup.sh` completes.

### Finding your Pi's IP Address:

After the Pis boot up, you'll need their IP addresses to SSH into them.
*   **Method 1 (Router):** Check your Wi-Fi router's connected devices list.
*   **Method 2 (Network Scan):** Use a network scanning tool on your laptop (e.g., `nmap -sn 192.168.1.0/24` if your network is `192.168.1.x`).

---

## Part 2: Your First Web Server

**Goal:** Students will SSH into their Pi, install Nginx, and serve a simple, personalized web page.

1.  **Concept:** Explain SSH (Secure Shell) for remote command-line access and what a web server (like Nginx) does.
2.  **Action:**
    *   Students use an SSH client (Terminal on Mac/Linux, PuTTY/WSL on Windows) to connect: `ssh pi@<YOUR_PI_IP_ADDRESS>`.
    *   The `first_boot_setup.sh` script has already installed Nginx and created a personalized `index.html` page.
3.  **Verification:** From their laptops, students open a browser to `http://<YOUR_PI_IP_ADDRESS>` and should see their unique page (e.g., "Hello from pi-1!").

---

## Part 3: Going Public with Cloudflare Tunnel

**Goal:** Expose the local Nginx server to the public internet using a secure tunnel.

**Concept:** Explain the problem (NAT, firewalls) that prevents the world from seeing their Pi. Introduce Cloudflare Tunnel as a secure solution that doesn't require port forwarding.

### Manual Cloudflare Tunnel Setup Instructions (to be performed on each Pi after first boot):

1.  **SSH into your Raspberry Pi:**
    ```bash
    ssh pi@<YOUR_PI_IP_ADDRESS>
    ```
2.  **Authenticate Cloudflared:**
    *   Run the login command:
        ```bash
        cloudflared tunnel login
        ```
    *   This command will output a URL. Copy this URL and paste it into a web browser on your laptop.
    *   Log in to your Cloudflare account (the one where your domain `my-pi-workshop.com` is registered).
    *   Select your domain.
    *   Once authenticated in the browser, you can close the browser tab. The `cloudflared` command on your Pi should now show "You have successfully logged in." and a `cert.pem` file will be created in `~/.cloudflared/`.

3.  **Create the Tunnel:**
    *   Choose a unique name for your tunnel (e.g., `my-pi-tunnel-1`, `my-pi-tunnel-2`, `my-pi-tunnel-3`).
    *   Run the create command:
        ```bash
        cloudflared tunnel create my-pi-tunnel-<PI_NUMBER>
        ```
    *   This will output a Tunnel ID (UUID) and create a credentials file (e.g., `~/.cloudflared/<UUID>.json`). **Make a note of the Tunnel ID.**

4.  **Move Credentials File:**
    *   The `first_boot_setup.sh` script expects the credentials file in `/etc/cloudflared/`. Move it there:
        ```bash
        sudo mv ~/.cloudflared/<YOUR_TUNNEL_UUID>.json /etc/cloudflared/
        ```

5.  **Update `config.yml`:**
    *   Edit the placeholder `config.yml` created by the first-boot script:
        ```bash
        sudo nano /etc/cloudflared/config.yml
        ```
    *   Replace `<YOUR_TUNNEL_UUID>` with the actual Tunnel ID you noted in step 3.
    *   Ensure the `credentials-file` path is correct (it should match the UUID).
    *   The `hostname` in the `ingress` section should already be set correctly based on your Pi's hostname (e.g., `pi-1.my-pi-workshop.com`).

6.  **Configure DNS Record (in Cloudflare Dashboard):**
    *   Go to your Cloudflare Dashboard (`dash.cloudflare.com`).
    *   Select your domain (`my-pi-workshop.com`).
    *   Go to "DNS" -> "Records".
    *   Add a new `CNAME` record:
        *   **Type:** `CNAME`
        *   **Name:** `pi-<PI_NUMBER>` (e.g., `pi-1`)
        *   **Target:** The UUID of your tunnel followed by `.cfargotunnel.com` (e.g., `<YOUR_TUNNEL_UUID>.cfargotunnel.com`).
        *   **Proxy status:** "Proxied" (orange cloud).
        *   Save the record.

7.  **Start the Cloudflared Tunnel Service:**
    *   Now that `cloudflared` is authenticated, the tunnel is created, credentials are in place, `config.yml` is updated, and DNS is configured, you can start the systemd service:
        ```bash
        sudo systemctl start cloudflared-tunnel.service
        sudo systemctl status cloudflared-tunnel.service
        ```
    *   Verify that the service is running without errors.

8.  **Test the Tunnel:**
    *   Open a web browser on your laptop and navigate to `https://pi-<PI_NUMBER>.my-pi-workshop.com` (e.g., `https://pi-1.my-pi-workshop.com`). You should see your personalized Nginx "Hello from Raspberry Pi X!" page.

---

## Part 4: A Dynamic Photo App

**Goal:** Replace the static page with a simple Python web app for uploading and viewing photos.

**Concept:** Explain the difference between a static site (Nginx serving HTML) and a dynamic web application (Python running code).

1.  **Action (On each Pi):**
    *   The `first_boot_setup.sh` script has already copied the `photo_app` to `/home/pi/photo_app`, installed `python3-pip`, and enabled/started the `photo-app.service`.
    *   The Python app is configured to run on port `8000`.
    *   **Crucially:** You need to update your Cloudflare Tunnel's `config.yml` to point to the Python app's port instead of Nginx.
        *   Edit `/etc/cloudflared/config.yml`:
            ```bash
            sudo nano /etc/cloudflared/config.yml
            ```
        *   Change `service: http://localhost:80` to `service: http://localhost:8000`.
        *   Restart the `cloudflared-tunnel.service`:
            ```bash
            sudo systemctl restart cloudflared-tunnel.service
            ```
2.  **Interaction:** Students can now visit their unique URL (e.g., `https://pi-1.my-pi-workshop.com`), upload a photo, and see it in the gallery.

---

## Part 5: Demonstrating the Single Point of Failure

**Goal:** Physically demonstrate the fragility of a single-server setup.

**Concept:** Introduce the "Single Point of Failure" (SPOF).

1.  **Demonstration:**
    *   All students should have their photo galleries open.
    *   The instructor unplugs **one** of the Raspberry Pis.
    *   The student whose Pi was unplugged will see their site go down. Everyone else's is still up.
    *   **Discussion:** What happens if this is a real business? You lose customers and money. How can we fix this?

---

## Part 6: Building a Resilient System with Syncthing

**Goal:** Create a truly fault-tolerant system by replicating storage across all nodes using Syncthing, and using Cloudflare for DNS-level failover.

### Concept 1: Decentralized Storage with Syncthing

We previously identified that using one Pi as a file server (with NFS) creates a new single point of failure. To solve this, we will use **Syncthing** to create a decentralized storage cluster. Each Pi will have a complete, identical copy of all the photos, and they will automatically keep each other in sync.

The `first_boot_setup.sh` script has already installed Syncthing and configured it to run as a service for the `pi` user. The following steps must be performed manually on each Pi to connect them together.

# Syncthing Setup Guide: Creating a Decentralized Storage Cluster

**Goal:** To connect all three Raspberry Pis in a peer-to-peer network to automatically and continuously synchronize the `/home/pi/photos` directory. This eliminates the single point of failure of an NFS server.

**Concept:** Syncthing is a private, secure, and decentralized file synchronization tool. Each Pi will run Syncthing, and they will all watch the same folder. When you upload a photo to one Pi, Syncthing will automatically copy that photo to the other two. If a Pi goes offline, the others still have all the files.

---

### Step 1: Access the Syncthing Web GUI via SSH Port Forwarding

The Syncthing web interface runs on each Pi at `localhost:8384`. To access it from your laptop's browser, you need to create an SSH tunnel.

1.  **Open a *new* terminal window** on your laptop (do not close your existing SSH session).

2.  In this new terminal, run the following command. This command forwards port `8384` from the Raspberry Pi to port `8384` on your own machine.

    ```bash
    # Replace <YOUR_PI_IP_ADDRESS> with the IP of the Pi you want to configure
    ssh -L 8384:localhost:8384 pi@<YOUR_PI_IP_ADDRESS>
    ```

3.  Enter your Pi's password when prompted. Keep this terminal window open.

4.  Now, open a web browser on your laptop and go to:
    [http://localhost:8384](http://localhost:8384)

5.  You should see the Syncthing interface. It may ask if you want to allow anonymous usage reporting. You can choose your preference.

**You will need to repeat this SSH port forwarding process for each of the three Pis to configure them.** It's often easiest to open a separate terminal for each one.

---

### Step 2: Secure the GUI and Get the Device ID

For the very first Pi you connect to:

1.  You will see a warning at the top: **"GUI Authentication Not Set"**.
2.  Click on **"Settings"**.
3.  Go to the **"GUI"** tab.
4.  Enter a **"GUI Username"** (e.g., `admin`) and a strong **"GUI Password"**.
5.  Click **"Save"**. The page will reload and ask for the username and password you just set.
6.  Now, go to the **"Actions"** menu (top right) and select **"Show ID"**.
7.  You will see a long string of characters. This is this Pi's unique **Device ID**. Copy it into a text file. It will look something like `ABCD123-EGF456-HIJ789-...`.
8.  Label it "Pi 1 ID".

**Repeat this process for Pi 2 and Pi 3**, making sure to note down the unique Device ID for each one. At the end, you should have three Device IDs saved.

---

### Step 3: Connect the Devices

Now we will tell the Pis about each other.

1.  **On Pi 1's GUI:**
    *   At the bottom right, click **"+ Add Remote Device"**.
    *   Enter the **Device ID** for **Pi 2**.
    *   Give it a **Device Name** (e.g., `pi-2`).
    *   Go to the **"Sharing"** tab and check the box next to the `Default Folder`. We will reconfigure this later, but this helps with auto-discovery.
    *   Click **"Save"**.

2.  **On Pi 2's GUI:**
    *   After a minute, you should see a prompt at the top saying **"Device pi-1 wants to connect"**. Click **"Add Device"**.
    *   Give it the name `pi-1` and click **"Save"**.
    *   Now, on Pi 2's GUI, click **"+ Add Remote Device"** and add **Pi 3's** Device ID, naming it `pi-3`.

3.  **On Pi 3's GUI:**
    *   You should get a connection request from Pi 2. Accept it.
    *   Now, on Pi 3's GUI, click **"+ Add Remote Device"** and add **Pi 1's** Device ID, naming it `pi-1`.

4.  **Finalize Connections:**
    *   Go back to Pi 1's GUI. You should have a connection request from Pi 3. Accept it.
    *   At this point, if you look at the "Remote Devices" panel on any of the Pis, you should see the other two listed.

---

### Step 4: Share the `photos` Directory

Now we will stop sharing the "Default Folder" and share our actual `photos` directory.

1.  **On Pi 1's GUI:**
    *   Click on the "Default Folder" in the left panel.
    *   Click **"Edit"**.
    *   **General Tab:**
        *   **Folder Label:** `Photos`
        *   **Folder Path:** `/home/pi/photos` (Make sure this is the exact path).
    *   **Sharing Tab:**
        *   Uncheck the "Default Folder" if it's checked for any device.
        *   Check the boxes for `pi-2` and `pi-3`.
    *   Click **"Save"**.

2.  **On Pi 2 and Pi 3's GUIs:**
    *   After a moment, a prompt will appear at the top: **"pi-1 wants to share folder 'Photos'"**.
    *   Click **"Add"**.
    *   A dialog will pop up. The most important setting is the **Folder Path**. Set it to `/home/pi/photos`.
    *   Click **"Save"**.

---

### Step 5: Verification

You are now finished with the configuration!

*   On each Pi's GUI, you should see the "Photos" folder listed.
*   Under "Remote Devices", it should show that the folder is shared with the other two Pis.
*   The folder status should change from "Unshared" to "Up to Date" after a few moments.

**To test it:**
1.  Go to the web app for any of the Pis (e.g., `https://pi-1.my-pi-workshop.com`).
2.  Upload a photo.
3.  Within a few seconds, you should be able to refresh the web app for **Pi 2** and **Pi 3** and see the same photo appear!

You have successfully created a decentralized, resilient storage cluster.

### Concept 2: Automatic Failover (Cloudflare Load Balancing)

We need one domain that intelligently sends users to a *working* server.

### Instructions for Cloudflare DNS and Health Check Configuration:

This configuration will enable Cloudflare to load balance traffic across your Raspberry Pi tunnels and automatically failover if one Pi goes offline.

**Prerequisites:**

*   You have a Cloudflare account with a registered domain (e.g., `my-pi-workshop.com`).
*   You have successfully set up Cloudflare Tunnels for each of your Raspberry Pi tunnels (e.g., `pi-1.my-pi-workshop.com`, `pi-2.my-pi-workshop.com`, `pi-3.my-pi-workshop.com`) as described in Part 3 of the workshop plan.
*   Your Python photo app is running on each Pi and includes the `/health` endpoint.

**Steps:**

1.  **Log in to Cloudflare Dashboard:**
    *   Go to [dash.cloudflare.com](https://dash.cloudflare.com/) and log in to your account.
    *   Select your domain (e.g., `my-pi-workshop.com`).

2.  **Navigate to DNS Records:**
    *   In the left-hand sidebar, click on "DNS" -> "Records".

3.  **Create the Main Application DNS Record:**
    *   Click the "Add record" button.
    *   **Type:** `CNAME`
    *   **Name:** `photos` (This will create `photos.my-pi-workshop.com`)
    *   **Target:** Enter a placeholder value for now, like `example.com` or `dummy.com`. We will change this to use the Load Balancer later.
    *   **Proxy status:** Ensure it's "Proxied" (orange cloud).
    *   Click "Save".

4.  **Navigate to Load Balancing:**
    *   In the left-hand sidebar, click on "Traffic" -> "Load Balancing".

5.  **Create a New Origin Pool:**
    *   Click "Create Pool".
    *   **Name:** `pi-photo-app-pool` (or similar descriptive name).
    *   **Origins:** Add an origin for each of your Raspberry Pi tunnels:
        *   **Origin Name:** `pi-1-origin`
        *   **Hostname/IP:** `pi-1.my-pi-workshop.com` (This is the CNAME you created for the individual tunnel).
        *   **Weight:** `1` (for equal distribution).
        *   Repeat for `pi-2-origin` (`pi-2.my-pi-workshop.com`) and `pi-3-origin` (`pi-3.my-pi-workshop.com`).
    *   **Health Monitors:**
        *   Click "Add Health Monitor".
        *   **Monitor Type:** `HTTP`
        *   **Path:** `/health` (This is the endpoint in your Python app).
        *   **Port:** `443` (since Cloudflare proxies traffic over HTTPS).
        *   **Interval:** `10s` (how often Cloudflare checks).
        *   **Timeout:** `5s` (how long to wait for a response).
        *   **Retries:** `2` (how many retries before marking unhealthy).
        *   Click "Save".
    *   Click "Save" to create the Origin Pool.

6.  **Create a New Load Balancer:**
    *   Click "Create Load Balancer".
    *   **Hostname:** `photos.my-pi-workshop.com` (This should match the CNAME record you created in step 3).
    *   **Default Origin Pools:** Select the `pi-photo-app-pool` you just created.
    *   **Traffic Steering:** Choose "Random" or "Least outstanding requests" for basic load balancing.
    *   **Fallback Pool:** (Optional but recommended) You can create a simple fallback pool pointing to a static "maintenance page" if all Pis go down. For this workshop, you can leave it blank or point to one of the existing origins.
    *   Click "Save".

7.  **Verify DNS Record Update:**
    *   Cloudflare will automatically update the `photos.my-pi-workshop.com` CNAME record to point to the Load Balancer. You might see it change to something like `photos.my-pi-workshop.com.cdn.cloudflare.net`.

### The Final Test:

*   All students now use the single URL: `https://photos.my-pi-workshop.com`.
*   Have several students upload photos. Everyone should see all photos because they're on the shared NFS drive.
*   The instructor unplugs a Pi again.
*   The website might show an error for a few seconds, but Cloudflare's Health Check will detect the failure and automatically redirect all traffic to the two remaining online Pis. The service heals itself!

---

## Workshop Files Summary

Here's a summary of the files created for this workshop:

### `plan.md`
(The initial high-level plan, now superseded by this guide)

### `boot.sh`
```bash
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
```

### `first_boot_setup.sh`
```bash
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
```

### `first_boot_setup.service`
```
[Unit]
Description=First Boot Setup Script
After=network-online.target

[Service]
Type=oneshot
ExecStart=/home/pi/first_boot_setup.sh
RemainAfterExit=yes
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
```

### `photo_app/app.py`
```python
import os
from flask import Flask, request, render_template, redirect, url_for, send_from_directory
from werkzeug.utils import secure_filename

app = Flask(__name__)

# Configuration
UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER', '/home/pi/photos')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure the upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    images = []
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        if allowed_file(filename):
            images.append(filename)
    return render_template('index.html', images=images, hostname=os.uname().nodename)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return redirect(request.url)
    file = request.files['file']
    if file.filename == '':
        return redirect(request.url)
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return redirect(url_for('index'))

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/health')
def health_check():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
```

### `photo_app/templates/index.html`
```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Pi Photo Gallery - {{ hostname }}</title>
    <style>
        body { font-family: sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
        .container { max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,.1); }
        h1 { color: #0056b3; text-align: center; margin-bottom: 30px; }
        .upload-form { margin-bottom: 30px; padding: 20px; border: 1px dashed #ccc; border-radius: 5px; text-align: center; }
        .upload-form input[type="file"] { display: block; margin: 0 auto 15px auto; }
        .upload-form input[type="submit"] { background-color: #28a745; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; }
        .upload-form input[type="submit"]:hover { background-color: #218838; }
        .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 15px; }
        .gallery img { width: 100%; height: 150px; object-fit: cover; border-radius: 5px; border: 1px solid #ddd; }
        .footer { text-align: center; margin-top: 40px; font-size: 0.9em; color: #777; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Pi Photo Gallery <small>({{ hostname }})</small></h1>

        <div class="upload-form">
            <h2>Upload a Photo</h2>
            <form method="POST" action="/upload" enctype="multipart/form-data">
                <input type="file" name="file" accept="image/*">
                <input type="submit" value="Upload">
            </form>
        </div>

        <h2>Your Photos</h2>
        <div class="gallery">
            {% for image in images %}
            <a href="{{ url_for('uploaded_file', filename=image) }}" target="_blank">
                <img src="{{ url_for('uploaded_file', filename=image) }}" alt="{{ image }}">
            </a>
            {% else %}
            <p>No photos uploaded yet.</p>
            {% endfor %}
        </div>

        <div class="footer">
            <p>Powered by Raspberry Pi & Flask</p>
        </div>
    </div>
</body>
</html>
```

### `photo_app/requirements.txt`
```
Flask
Werkzeug
```
