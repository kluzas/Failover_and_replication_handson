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
