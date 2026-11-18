#!/usr/bin/env bash
# Captures real build and test execution output for runtime verification discipline.
# Usage: ./scripts/capture-verify-log.sh <track_dir_or_id> "<command>"

set -uo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <track_dir_or_id> \"<command>\"" >&2
  exit 2
fi

TARGET="$1"
shift
CMD="$*"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TRACK_DIR="$(python3 - "$SCRIPT_DIR" "$TARGET" << 'PYEOF'
import os, sys
script_dir, target = sys.argv[1], sys.argv[2]
sys.path.insert(0, script_dir)
import gate_check
try:
    print(gate_check.resolve_track_dir(target))
except Exception as exc:
    sys.stderr.write(f"[capture-verify-log] {exc}\n")
    sys.exit(2)
PYEOF
)" || exit 2

LOG_FILE="$TRACK_DIR/verification.log"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

GIT_HEAD="$(git rev-parse HEAD 2>/dev/null || echo "none")"
if [ "$GIT_HEAD" != "none" ] && [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
  GIT_STATE="dirty"
else
  GIT_STATE="clean"
fi

{
  echo "================================================================================"
  echo "[VERIFY START] Timestamp: $TS | GitHEAD: $GIT_HEAD ($GIT_STATE)"
  echo "[COMMAND] $CMD"
  echo "--------------------------------------------------------------------------------"
} >> "$LOG_FILE"

bash -c "$CMD" > "$TMP_OUT" 2>&1
EXIT_CODE=$?

cat "$TMP_OUT" >> "$LOG_FILE"

if command -v shasum >/dev/null 2>&1; then
  OUTPUT_HASH="$(shasum -a 256 "$TMP_OUT" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
  OUTPUT_HASH="$(sha256sum "$TMP_OUT" | awk '{print $1}')"
else
  OUTPUT_HASH="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$TMP_OUT")"
fi

{
  echo "--------------------------------------------------------------------------------"
  echo "[VERIFY END] ExitCode: $EXIT_CODE | GitHEAD: ${GIT_HEAD:0:12} ($GIT_STATE) | OutputSHA256: ${OUTPUT_HASH:0:12}"
  echo "================================================================================"
} >> "$LOG_FILE"

python3 - "$TS" "$CMD" "$EXIT_CODE" "${OUTPUT_HASH:0:12}" "$GIT_HEAD" "$GIT_STATE" "$LOG_FILE" << 'PYEOF'
import json, sys
ts, cmd, code, sha, head, state, log_file = sys.argv[1:8]
print(json.dumps({
    "timestamp": ts,
    "command": cmd,
    "exit_code": int(code),
    "output_sha256": sha,
    "git_head": head,
    "git_state": state,
    "log_file": log_file,
}))
PYEOF

exit "$EXIT_CODE"
