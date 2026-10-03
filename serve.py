#!/usr/bin/env python3
"""Serves the dashboard + logs; POST /api/run triggers a check. Usage: ./serve.py [port]"""
import http.server, json, subprocess, sys, os
ROOT = os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", ""): self.path = "/dashboard/index.html"
        super().do_GET()
    def do_POST(self):
        if self.path != "/api/run": return self.send_error(404)
        p = subprocess.run(["bash", "healthmon.sh"], capture_output=True, text=True)
        b = json.dumps({"exit": p.returncode, "output": p.stdout.strip()}).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.end_headers(); self.wfile.write(b)
    def log_message(self, *a): pass
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
print(f"Dashboard: http://127.0.0.1:{port}"); http.server.ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
