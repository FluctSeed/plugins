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

if [ -d "$TARGET" ]; then
  TRACK_DIR="$TARGET"
elif [ -d "conductor/tracks/$TARGET" ]; then
  TRACK_DIR="conductor/tracks/$TARGET"
else
  # Monorepo search for module-level conductor/tracks/$TARGET
  FOUND="$(find . -maxdepth 5 -type d -path "*/conductor/tracks/$TARGET" 2>/dev/null | head -n 1)"
  if [ -n "$FOUND" ] && [ -d "$FOUND" ]; then
    TRACK_DIR="$FOUND"
  else
    mkdir -p "$TARGET"
    TRACK_DIR="$TARGET"
  fi
fi

LOG_FILE="$TRACK_DIR/verification.log"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TMP_OUT="$(mktemp)"

echo "================================================================================" >> "$LOG_FILE"
echo "[VERIFY START] Timestamp: $TS" >> "$LOG_FILE"
echo "[COMMAND] $CMD" >> "$LOG_FILE"
echo "--------------------------------------------------------------------------------" >> "$LOG_FILE"

bash -c "$CMD" > "$TMP_OUT" 2>&1
EXIT_CODE=$?

cat "$TMP_OUT" >> "$LOG_FILE"
OUTPUT_HASH="$(shasum -a 256 "$TMP_OUT" | awk '{print $1}')"
rm -f "$TMP_OUT"

echo "--------------------------------------------------------------------------------" >> "$LOG_FILE"
echo "[VERIFY END] ExitCode: $EXIT_CODE | OutputSHA256: ${OUTPUT_HASH:0:12}" >> "$LOG_FILE"
echo "================================================================================" >> "$LOG_FILE"

echo "{\"timestamp\":\"$TS\",\"command\":\"$CMD\",\"exit_code\":$EXIT_CODE,\"output_sha256\":\"${OUTPUT_HASH:0:12}\",\"log_file\":\"$LOG_FILE\"}"
exit $EXIT_CODE
