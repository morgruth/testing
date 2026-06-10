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
