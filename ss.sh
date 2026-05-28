#!/bin/bash
# Sudo server v2 — run with: sudo ./ss.sh
# Shows all commands and output in this terminal.

PORT=7331
TOKEN=$(openssl rand -hex 16)

if [ "$(id -u)" -ne 0 ]; then
    echo "Run me with sudo: sudo ./ss.sh"
    exit 1
fi

echo "══════════════════════════════════════════"
echo "  Sudo server on :${PORT}"
echo "  Token: ${TOKEN}"
echo "══════════════════════════════════════════"
echo ""

export SS_TOKEN="${TOKEN}"
export SS_PORT="${PORT}"

python3 << 'PYEOF'
import http.server, subprocess, json, os, sys, time

TOKEN = os.environ.get("SS_TOKEN", "")
PORT = int(os.environ.get("SS_PORT", "7331"))

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        auth = self.headers.get("X-Token", "")
        if auth != TOKEN:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"bad token")
            return

        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length))
        cmd = body.get("cmd", "")
        cwd = body.get("cwd", "/tmp")
        stdin_data = body.get("stdin", None)
        timeout = body.get("timeout", 30)

        # Print command to terminal
        print(f"\n\033[1;36m$ {cmd}\033[0m")
        if cwd != "/tmp":
            print(f"\033[2m  (cwd: {cwd})\033[0m")

        try:
            result = subprocess.run(
                cmd, shell=True, cwd=cwd,
                capture_output=True, timeout=timeout,
                input=stdin_data.encode() if stdin_data else None
            )
            stdout = result.stdout.decode("utf-8", errors="replace")
            stderr = result.stderr.decode("utf-8", errors="replace")

            # Print output to terminal
            if stdout:
                print(stdout, end="" if stdout.endswith("\n") else "\n")
            if stderr:
                print(f"\033[31m{stderr}\033[0m", end="" if stderr.endswith("\n") else "\n")
            if result.returncode != 0:
                print(f"\033[33mexit={result.returncode}\033[0m")

            resp = {"exit": result.returncode, "stdout": stdout, "stderr": stderr}
        except subprocess.TimeoutExpired:
            print(f"\033[31m[TIMEOUT after {timeout}s]\033[0m")
            resp = {"exit": -1, "stdout": "", "stderr": "timeout"}
        except Exception as e:
            print(f"\033[31m[ERROR: {e}]\033[0m")
            resp = {"exit": -1, "stdout": "", "stderr": str(e)}

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(resp).encode())

    def log_message(self, fmt, *args):
        pass  # suppress default HTTP logs

server = http.server.HTTPServer(("127.0.0.1", PORT), Handler)
print(f"Listening on 127.0.0.1:{PORT}...")
print("All commands will show here. Ctrl+C to stop.\n")
server.serve_forever()
PYEOF
