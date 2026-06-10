#!/bin/bash

WORKSPACE_DIR="/workspaces/testing"
CGI_DIR="$WORKSPACE_DIR/cgi-bin"

echo "[+] Updating apt and installing dependencies..."
sudo apt-get update && sudo apt-get install -y tor python3 php-cgi php-sqlite3

# 1. Configure Tor Hidden Service
echo "[+] Configuring Tor Hidden Service..."
TORRC="/etc/tor/torrc"
HS_DIR="/var/lib/tor/workspace_onion/"

# Append Tor configurations safely using sudo
if ! sudo grep -q "workspace_onion" "$TORRC"; then
    echo -e "\nHiddenServiceDir $HS_DIR" | sudo tee -a "$TORRC" > /dev/null
    echo "HiddenServicePort 80 127.0.0.1:8080" | sudo tee -a "$TORRC" > /dev/null
fi

# Restart Tor daemon to generate the address
sudo systemctl restart tor
echo "[+] Waiting for Tor to generate keys..."
sleep 4

# Print Onion URL
if sudo test -f "${HS_DIR}hostname"; then
    ONION_URL=$(sudo cat "${HS_DIR}hostname")
    echo "===================================================="
    echo "[*] SUCCESS! Your Hidden Service URL is:"
    echo "    http://$ONION_URL"
    echo "===================================================="
else
    echo "[-] Error: Tor hostname file not found. Check 'sudo journalctl -u tor'"
fi

# 2. Build local Workspace Directories
echo "[+] Setting up local workspace directories..."
mkdir -p "$CGI_DIR"

# 3. Create the PHP Script
echo "[+] Creating cgi-bin/index.php..."
cat << 'EOF' > "$CGI_DIR/index.php"
#!/usr/bin/usr/env php-cgi
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

    echo "<html><head><title>Workspace Hidden Service</title></head><body style='font-family:sans-serif;'>";
    echo "<h1>Hello from /workspaces/testing!</h1>";
    echo "<p>SQLite Visit Count: <strong>" . htmlspecialchars($count) . "</strong></p>";
    echo "</body></html>";

} catch (PDOException $e) {
    echo "Database error: " . htmlspecialchars($e->getMessage());
}
?>
EOF

# Ensure PHP file can execute as a script
chmod +x "$CGI_DIR/index.php"

# 4. Create Python CGI Server Launcher
echo "[+] Creating server.py..."
cat << 'EOF' > "$WORKSPACE_DIR/server.py"
import http.server
import os

class CustomCGIHandler(http.server.CGIHTTPRequestHandler):
    def setup(self):
        super().setup()

# Lock server execution inside your exact workspace
os.chdir('/workspaces/testing')

server_address = ('127.0.0.1', 8080)
httpd = http.server.HTTPServer(server_address, CustomCGIHandler)

print("[+] Local Python CGI Server running on http://127.0.0.1:8080")
print("[+] Access via Tor browser at your .onion URL")
print("[-] Press Ctrl+C to terminate.")

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\n[-] Shutting down server.")
    httpd.server_close()
EOF

echo "[+] Setup complete."
echo "[+] To run the server manually later, run: python3 server.py"
echo "----------------------------------------------------"

# 5. Execute server right away
python3 "$WORKSPACE_DIR/server.py"
