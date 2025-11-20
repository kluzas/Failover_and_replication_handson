### Workshop Title: From Zero to High-Availability: Building a Resilient Web Service with Raspberry Pi

**Target Audience:** 12th Grade Students
**Duration:** 4-6 hours (depending on pace)
**Hardware:** 3 Raspberry Pi (4 or 5 recommended), 3 SD Cards (16GB+), 3 Power Supplies, Laptops for students.

---

### Part 0: Pre-Workshop Preparation (Instructor's Task)

**Goal:** Have all necessary hardware, software, and accounts ready to ensure a smooth workshop.

1.  **Hardware Setup:**
    *   Ensure all 3 Raspberry Pis are functional.
    *   Have SD cards, readers, and power supplies for each.
2.  **Software & Accounts:**
    *   Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
    *   Create a [Cloudflare](https://www.cloudflare.com/) account and register a domain name (e.g., `my-pi-workshop.com`). This is crucial for the tunneling and DNS parts.
    *   Prepare the simple Python photo gallery application code.
3.  **Network Information:**
    *   Have the workshop's Wi-Fi SSID and password ready.

---

### Part 1: Headless Setup & First Connection (45 mins)

**Goal:** Students will flash an SD card with a pre-configured OS that automatically connects to Wi-Fi and has SSH enabled, allowing "headless" access.

1.  **Concept:** Explain what "headless" means (no monitor, keyboard, or mouse connected to the Pi).
2.  **Tool:** Introduce the Raspberry Pi Imager.
3.  **Action:**
    *   Students use the Imager to select "Raspberry Pi OS Lite (64-bit)".
    *   In the advanced settings (`Ctrl+Shift+X`):
        *   Set a hostname (e.g., `pi-1`, `pi-2`, `pi-3`). **This must be unique for each Pi.**
        *   Enable SSH (use password authentication for simplicity).
        *   Set a username (`pi`) and a memorable password.
        *   Configure the Wi-Fi network credentials.
4.  **Execution:**
    *   Flash the SD cards, insert them into the Pis, and power them on.
    *   **Challenge:** Find the IP address of your Pi.
        *   **Method 1 (Router):** Instructor checks the router's DHCP client list.
        *   **Method 2 (Network Scan):** Use a tool like `nmap` (`nmap -sn 192.168.1.0/24`) or a phone app to scan the network.
5. **Install requirements**
```
apt-get install openssh-server curl nginx

```
---

### Part 2: Your First Web Server (45 mins)

**Goal:** Students will SSH into their Pi, install Nginx, and serve a simple, personalized web page.

1.  **Concept:** Explain SSH (Secure Shell) for remote command-line access and what a web server (like Nginx) does.
2.  **Action:**
    *   Students use an SSH client (Terminal on Mac/Linux, PuTTY/WSL on Windows) to connect: `ssh pi@<IP_ADDRESS>`.
    *   Run update commands: `sudo apt update && sudo apt upgrade -y`.
    *   Install Nginx: `sudo apt install nginx -y`.
    *   Verify it's running: `systemctl status nginx`.
3.  **Personalization:**
    *   Navigate to the web root: `cd /var/www/html`.
    *   Edit the main page: `sudo nano index.html`.
    *   Replace the content with: `<h1>Hello from Raspberry Pi 1!</h1>` (or 2, or 3).
4.  **Verification:** From their laptops, students open a browser to `http://<IP_ADDRESS>` and see their unique page.

---

### Part 3: Going Public with Cloudflare Tunnel (60 mins)

**Goal:** Expose the local Nginx server to the public internet using a secure tunnel.

1.  **Concept:** Explain the problem (NAT, firewalls) that prevents the world from seeing their Pi. Introduce Cloudflare Tunnel as a secure solution that doesn't require port forwarding.
2.  **Action (On each Pi):**
    *   Follow Cloudflare's instructions to install `cloudflared`.
    *   Authenticate the agent: `cloudflared tunnel login`. This will open a browser link to log into the Cloudflare account.
    *   Create a tunnel: `cloudflared tunnel create my-pi-tunnel-1` (use 1, 2, 3 for each Pi).
    *   Create a DNS record to link the tunnel to a public subdomain: `cloudflared tunnel route dns my-pi-tunnel-1 pi-1.my-pi-workshop.com`.
    *   Run the tunnel, pointing it to the Nginx service: `cloudflared tunnel run --url localhost:80 my-pi-tunnel-1`.

3.  **Verification:** Students can now access `https://pi-1.my-pi-workshop.com` from any device on the internet and see their page. This is a huge "wow" moment.

---

### Part 4: A Dynamic Photo App (60 mins)

**Goal:** Replace the static page with a simple Python web app for uploading and viewing photos.

1.  **Concept:** Explain the difference between a static site (Nginx serving HTML) and a dynamic web application (Python running code).
2.  **Action (On each Pi):**
    *   Install Python and Pip: `sudo apt install python3-pip -y`.
    *   Provide the students with the Python app code (e.g., via `git clone`).
    *   Install dependencies: `pip install -r requirements.txt` (e.g., Flask or FastAPI, Pillow).
    *   Run the app: `python3 app.py`.
    *   **Crucially:** Stop the previous tunnel command and update it to point to the Python app's port (e.g., 8000): `cloudflared tunnel run --url localhost:8000 my-pi-tunnel-1`.

3.  **Interaction:** Students can now visit their unique URL, upload a photo, and see it in the gallery.

---

### Part 5: Demonstrating the Single Point of Failure (15 mins)

**Goal:** Physically demonstrate the fragility of a single-server setup.

1.  **Concept:** Introduce the "Single Point of Failure" (SPOF).
2.  **Demonstration:**
    *   All students should have their photo galleries open.
    *   The instructor unplugs **one** of the Raspberry Pis.
    *   The student whose Pi was unplugged will see their site go down. Everyone else's is still up.
    *   **Discussion:** What happens if this is a real business? You lose customers and money. How can we fix this?

---

### Part 6: Building a Resilient System (75 mins)

**Goal:** Create a fault-tolerant system using shared storage (NFS) and DNS-level failover (Cloudflare).

1.  **Concept 1: Shared Storage.** If a Pi goes down, how can another Pi serve its files? The files must be in a shared location. Introduce Syncthing.
    *   **Action (on all three Pis):**
        *   Install Syncthing: `sudo apt install syncthing -y`.
        *   Start Syncthing and enable it to run on boot:
            ```bash
            sudo systemctl enable syncthing@pi.service
            sudo systemctl start syncthing@pi.service
            ```
        *   Access the Syncthing web UI: Syncthing runs on port 8384. You might need to enable access through the firewall (`sudo ufw allow 8384/tcp`) or use an SSH tunnel (`ssh -L 8384:localhost:8384 pi@<IP_ADDRESS>`).
        *   **Configure Syncthing:**
            *   On each Pi, create the shared photos directory: `sudo mkdir -p /mnt/shared_photos`.
            *   In the Syncthing web UI, add the other two Pis as remote devices. You'll need their device IDs (found in the "Actions" -> "Show ID" menu).
            *   Create a new shared folder in Syncthing, pointing to `/mnt/shared_photos`. Share this folder with the other two devices. Ensure "Send & Receive" is selected for all devices.
            *   Wait for the folders to synchronize.

    *   **Code Change:** Modify the Python app on **all three Pis** to save and read photos from `/mnt/shared_photos`.

2.  **Concept 2: Automatic Failover.** We need one domain that intelligently sends users to a *working* server.
    *   **Action (in Cloudflare Dashboard):**
        *   Create a single new DNS `A` record (e.g., `photos.my-pi-workshop.com`) and point it to a dummy IP like `192.0.2.1`.
        *   For this DNS record, configure it to use your three tunnels (`my-pi-tunnel-1`, `my-pi-tunnel-2`, `my-pi-tunnel-3`) as origins.
        *   Configure **Health Checks** to ping a specific endpoint on each origin (e.g., `/health`). You'll need to add a simple `/health` route to your Python app that returns a `200 OK`.
        *   Cloudflare will now automatically detect when a tunnel goes down (because the health check fails) and stop sending traffic to it.

3.  **The Final Test:**
    *   All students now use the single URL: `https://photos.my-pi-workshop.com`.
    *   Have several students upload photos. Everyone should see all photos because they're on the Syncthing shared folder.
    *   The instructor unplugs a Pi again.
    *   The website might show an error for a few seconds, but Cloudflare's Health Check will detect the failure and automatically redirect all traffic to the two remaining online Pis. The service heals itself!