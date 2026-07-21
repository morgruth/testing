#!/bin/bash
WORKSPACE_DIR="/workspaces/testing"
CGI_DIR="$WORKSPACE_DIR/cgi-bin"
TORRC="/etc/tor/torrc"
HS_DIR="/var/lib/tor/workspace_onion/"
echo "[+] Updating apt and installing dependencies..."
sudo apt-get update && sudo apt-get install -y tor python3 php-cgi php-sqlite3
# 1. Configure Tor Hidden Service Configuration Lines
echo "[+] Configuring Tor Hidden Service inside /etc/tor/torrc..."
if ! sudo grep -q "workspace_onion" "$TORRC"; then
    echo -e "\nHiddenServiceDir $HS_DIR" | sudo tee -a "$TORRC" > /dev/null
    echo "HiddenServicePort 80 127.0.0.1:8080" | sudo tee -a "$TORRC" > /dev/null
fi
# 2. Build and Secure the Hidden Service Directory (Container Fix)
echo "[+] Instantiating and locking down Tor cryptographic directories..."
sudo mkdir -p "$HS_DIR"
sudo chown -R debian-tor:debian-tor "$HS_DIR"
sudo chmod 700 "$HS_DIR"
# 3. Start Tor Using Container-Friendly Service Manager
echo "[+] Starting Tor network daemon via container service manager..."
sudo service tor restart
echo "[+] Waiting 5 seconds for Tor to establish circuits and generate keys..."
sleep 5
# 4. Print Onion URL
if sudo test -f "${HS_DIR}hostname"; then
    ONION_URL=$(sudo cat "${HS_DIR}hostname")
    echo "===================================================="
    echo "[*] SUCCESS! Your Hidden Service URL is:"
    echo "    http://$ONION_URL"
    echo "===================================================="
else
    echo "[-] Error: Tor hostname file not found."
    echo "[*] Attempting manual direct-binary Tor fallback start..."
    sudo tor &
    sleep 5
    if sudo test -f "${HS_DIR}hostname"; then
        ONION_URL=$(sudo cat "${HS_DIR}hostname")
        echo "===================================================="
        echo "[*] SUCCESS (Fallback)! Your Hidden Service URL is:"
        echo "    http://$ONION_URL"
        echo "===================================================="
    else
        echo "[-] Critical: Failed to generate Onion keys. Check system logs."
    fi
fi
# 5. Build Local Workspace Directories
echo "[+] Setting up local workspace directories..."
mkdir -p "$CGI_DIR"
# 6. Create the PHP Script with Custom Database Relative Mapping
echo "[+] Creating cgi-bin/index.php..."
cat << 'EOF' > "$CGI_DIR/index.php"
#!/usr/bin/env php-cgi
<?php
// Mandatory CGI Header
echo "Content-Type: text/html\r\n\r\n";
try {
    // Relative path to keep the database in your testing root folder
    $db = new PDO('sqlite:../database.sqlite');
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->exec("CREATE TABLE IF NOT EXISTS visits (id INTEGER PRIMARY KEY, ts TEXT)");
    $stmt = $db->prepare("INSERT INTO visits (ts) VALUES (:ts)");
    $stmt->execute([':ts' => date('Y-m-d H:i:s')]);
    $count = $db->query("SELECT COUNT(*) FROM visits")->fetchColumn();
    echo "<html><head><title>Workspace Hidden Service</title></head><body style='font-family:sans-serif; background:#f4f4f4; padding:40px;'>";
    echo "<div style='background:white; padding:20px; border-radius:8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width:500px; margin:0 auto;'>";
    echo "<h1>Hello from /workspaces/testing!</h1>";
    echo "<p>Your clean URL routing layer is active.</p>";
    echo "<p>SQLite Visit Count: <strong style='color:#007bff;'>" . htmlspecialchars($count) . "</strong></p>";
    echo "</div></body></html>";
} catch (PDOException $e) {
    echo "Database error: " . htmlspecialchars($e->getMessage());
}
?>
EOF
# Ensure PHP file can execute as a script
chmod +x "$CGI_DIR/index.php"
# 7. Create Python Clean-URL Server Launcher
echo "[+] Creating server.py..."
cat << 'EOF' > "$WORKSPACE_DIR/server.py"
import http.server
import os
import sys
import thread
#run in thread mode
class CleanURLCGIHandler(http.server.CGIHTTPRequestHandler):
    def translate_path(self, path):
        """Intercepts clean routing URLs and maps them internally to the CGI structure."""
        if path == '/' or path == '/index.php':
            path = '/cgi-bin/index.php'
        return super().translate_path(path)
    def is_cgi(self):
        """Forces Python to treat our rewritten paths as executable scripts."""
        if "cgi-bin" in self.path or self.path == '/' or self.path == '/index.php':
            return True
        return super().is_cgi()
# Lock server execution inside your exact workspace
os.chdir('/workspaces/testing')
server_address = ('127.0.0.1', 8080)
httpd = http.server.HTTPServer(server_address, CleanURLCGIHandler)
print("[+] Local Python CGI Router running on http://127.0.0.1:8080")
print("[+] Clean URL Mapping Enabled: '/' -> '/cgi-bin/index.php'")
print("[-] Press Ctrl+C to terminate.")
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\n[-] Shutting down server.")
    httpd.server_close()
    sys.exit(0)
EOF
echo "[+] Setup execution completed."
echo "[+] Launching your web routing stack now..."
echo "----------------------------------------------------"
# 8. Execute Clean URL Python Server
python3 "$WORKSPACE_DIR/server.py"
echo "$"
# whereis "appname"> /dev/null 2> README.md append to it and you know your refrigerator running through every thing here
whereis php
whereis tor
#whereis appach2
whareis lightsql
whereis autossh
whereis python
whereis pip
whereis source
#build a python enviroment
python -m python -m venv ?
find ? >> README.md

#put this First
sudo nano /etc/resolv.conf
#reverse from user@publick-server-ip to your box 9000:localhost:22 is your target
# they got rid of nc command
#               target computer     cacs computer
#ssh -f -N -R 9000:localhost:22 user@public-server-ip
# from the localhost grabe the .ssh copy the ssh folder
#autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R 9000:localhost:22 user@public-server-ip

