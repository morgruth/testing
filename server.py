import http.server
import os
import sys

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
