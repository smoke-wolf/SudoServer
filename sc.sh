#!/bin/bash
# sc.sh — SudoServer client helper
# Usage: SS_TOKEN=<token> ./sc.sh "command" [cwd]

CMD="$1"
CWD="${2:-$(pwd)}"
PORT=${SS_PORT:-7331}

if [ -z "$SS_TOKEN" ] || [ -z "$CMD" ]; then
    echo "Usage: SS_TOKEN=<token> ./sc.sh \"command\" [cwd]"
    exit 1
fi

payload=$(python3 -c "import json,sys; print(json.dumps({'cmd': sys.argv[1], 'cwd': sys.argv[2]}))" "$CMD" "$CWD")

curl -s -X POST "http://127.0.0.1:${PORT}" \
     -H "X-Token: ${SS_TOKEN}" \
     -H "Content-Type: application/json" \
     -d "$payload" | python3 -c "
import json, sys
r = json.load(sys.stdin)
if r['stdout']: print(r['stdout'], end='')
if r['stderr']: print(r['stderr'], end='', file=sys.stderr)
sys.exit(r['exit'])
"
