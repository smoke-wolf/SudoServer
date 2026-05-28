# SudoServer

if you run Claude Code with `--dangerously-skip-permissions` it still can't use `sudo` — the password prompt interrupts the pipe and breaks the flow. so even in full dangerous mode, anything that needs root just dies.

this fixes that. you run `ss.sh` once with sudo upfront, it gives you a random token, you pass the token to Claude, and from there it can POST commands that run as root through the server. no more prompts mid-session. every command and its output shows up live in the terminal you started it in so you can see exactly what's going on.

---

## setup

```bash
sudo ./ss.sh
```

```
══════════════════════════════════════════
  SudoServer on 127.0.0.1:7331
  Token: a3f8c2d1e4b8...
  Copy the token — Claude needs it.
══════════════════════════════════════════
```

then just tell Claude the port and token. that's it.

---

## using it from the terminal

`sc.sh` is a thin bash wrapper if you want to send commands manually:

```bash
export SS_TOKEN=a3f8c2...
./sc.sh "diskutil list"
./sc.sh "mount -t tmpfs tmpfs /mnt" /tmp
```

or raw curl if you prefer:

```bash
curl -s -X POST http://127.0.0.1:7331 \
  -H "X-Token: $SS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cmd": "whoami", "cwd": "/tmp"}'
```

---

## api

`POST /` — runs a command as root and returns output

request body (JSON):

| field | type | default | notes |
|-------|------|---------|-------|
| `cmd` | string | — | the command to run (required) |
| `cwd` | string | `/tmp` | working directory |
| `stdin` | string | — | piped to the process |
| `timeout` | int | `30` | seconds before it gets killed |

response:

```json
{ "exit": 0, "stdout": "...", "stderr": "..." }
```

---

## security stuff

- only binds to `127.0.0.1`, not reachable from the network
- token is random (`openssl rand -hex 16`) every time you start it, never written to disk
- kill the process and the access is gone, nothing persists
- it runs commands as root so don't leave it sitting open when you're not using it

---

## requirements

- python 3 (no pip installs, stdlib only)
- openssl (already on macos and most linux)

---

## change the port

```bash
SS_PORT=9000 sudo ./ss.sh
```

---

*built with [Claude](https://claude.ai)*
