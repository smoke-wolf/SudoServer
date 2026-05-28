# SudoServer

A minimal localhost HTTP bridge that lets Claude Code (or any tool) run `sudo` commands interactively — without needing a persistent TTY or password prompt mid-session.

You run the server once with `sudo`. It prints a one-time token. You paste the token to Claude. Claude fires HTTP requests; they run as root and you see every command and its output live in your terminal.

---

## Why

Claude Code cannot call `sudo` interactively — the password prompt blocks the pipe. The normal workaround (NOPASSWD sudoers entries) is a permanent hole. SudoServer is a zero-config alternative: one `sudo` at startup, token-authenticated, localhost-only, and it dies when you Ctrl+C.

---

## Quick start

```bash
# Terminal 1 — start the server
sudo ./ss.sh

# ══════════════════════════════════════════
#   SudoServer on 127.0.0.1:7331
#   Token: a3f8c2...
#   Copy the token — Claude needs it.
# ══════════════════════════════════════════
```

Then tell Claude:

> The sudo server is running on port 7331 with token `a3f8c2...`

Claude will POST commands to it. You will see every command and output live in Terminal 1.

---

## Client (sc.sh)

```bash
export SS_TOKEN=a3f8c2...
./sc.sh "df -h"
./sc.sh "mount /dev/disk4s1 /mnt" /tmp
```

Or with raw curl:

```bash
curl -s -X POST http://127.0.0.1:7331   -H "X-Token: $SS_TOKEN"   -H "Content-Type: application/json"   -d '{"cmd":"whoami","cwd":"/tmp"}' | python3 -c "import json,sys; r=json.load(sys.stdin); print(r["stdout"])"
```

---

## API

POST /  — execute a command as root

Headers: X-Token: <token>

Body (JSON):
  cmd      string   shell command to run (required)
  cwd      string   working directory (default /tmp)
  stdin    string   data piped to stdin (optional)
  timeout  int      seconds before kill (default 30)

Response (JSON):
  exit     int      exit code
  stdout   string   standard output
  stderr   string   standard error

---

## Security

- Binds to 127.0.0.1 only
- Token is openssl rand -hex 16, fresh each run, never stored
- No persistence: kill the process, access is gone
- Commands run as root — do not leave it running unattended

---

## Requirements

- macOS or Linux
- Python 3 (stdlib only)
- openssl

---

## Custom port

```bash
SS_PORT=9000 sudo ./ss.sh
```
