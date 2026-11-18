#!/usr/bin/env bash
# ==============================================================================
# Fluctseed Plugin Integrity Verifier & Offline Local Development Helper
# Primary user installation uses Native Plugin Marketplaces (claude, codex, agy).
# This script validates repository bundle integrity (--check) or links only
# Fluctseed-owned entries into a target workspace without deleting user files.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR=""
CHECK_ONLY=true
USE_COPY=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --check          Validate all core plugin manifests, skills, agents, rules, and scripts (default)
  --target <dir>   Link Fluctseed skills/agents/rules non-destructively into <dir> for offline dev testing
  --copy           Copy Fluctseed entries instead of symlinking when used with --target
  -h, --help       Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --target)
      [[ $# -ge 2 ]] || { echo "[ERROR] --target requires a directory" >&2; exit 2; }
      TARGET_DIR="$(cd "$2" && pwd)"
      CHECK_ONLY=false
      shift 2
      ;;
    --copy)
      USE_COPY=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

CORE_SKILLS=("setup" "brainstorm" "new-track" "implement" "review" "status" "revert")
PERSONAS=(
  "zoom-out" "inventive-catalyst" "comprehension" "design-critic"
  "structural" "style" "implementation-readiness" "codebase-details"
  "synthesizer" "bootstrap-orchestrator" "implementer" "comment-auditor"
)
CORE_RULES=("lifecycle-workflow" "design-audit-discipline" "implementation-discipline" "interactive-questions")

chmod +x "$PLUGIN_ROOT/scripts/resume.py" \
         "$PLUGIN_ROOT/scripts/gate_check.py" \
         "$PLUGIN_ROOT/scripts/prepare_audit_context.py" \
         "$PLUGIN_ROOT/scripts/log.sh" \
         "$PLUGIN_ROOT/scripts/capture-verify-log.sh" \
         "$PLUGIN_ROOT/scripts/check-plan.mjs" \
         "$PLUGIN_ROOT/scripts/worktree-audit.sh" 2>/dev/null || true

ERRORS=0
check_path() {
  if [[ ! -e "$1" ]]; then
    echo "  [MISSING] $1" >&2
    ERRORS=$((ERRORS + 1))
  fi
}

echo "[Verify] Checking Fluctseed plugin source bundle at $PLUGIN_ROOT..."
for manifest in \
  "$PLUGIN_ROOT/plugin.json" \
  "$PLUGIN_ROOT/.claude-plugin/plugin.json" \
  "$PLUGIN_ROOT/.claude-plugin/marketplace.json" \
  "$PLUGIN_ROOT/.codex-plugin/plugin.json" \
  "$PLUGIN_ROOT/.agents/plugins/marketplace.json" \
  "$PLUGIN_ROOT/LICENSE" \
  "$PLUGIN_ROOT/NOTICE" \
  "$PLUGIN_ROOT/assets/icon.svg"; do
  check_path "$manifest"
done

for skill in "${CORE_SKILLS[@]}"; do
  check_path "$PLUGIN_ROOT/skills/$skill/SKILL.md"
done

for persona in "${PERSONAS[@]}"; do
  check_path "$PLUGIN_ROOT/agents/${persona}.md"
done

for rule in "${CORE_RULES[@]}"; do
  check_path "$PLUGIN_ROOT/rules/${rule}.md"
done

if ! python3 - "$PLUGIN_ROOT" <<'PY'
import glob, json, os, re, sys
root = sys.argv[1]
base_ver = json.load(open(os.path.join(root, "plugin.json")))["version"]
mismatches = []
for rel, getter in [
    (".claude-plugin/plugin.json", lambda d: [d["version"]]),
    (".claude-plugin/marketplace.json", lambda d: [d["version"], d["plugins"][0]["version"]]),
    (".codex-plugin/plugin.json", lambda d: [d["version"]]),
    (".agents/plugins/marketplace.json", lambda d: [d["plugins"][0]["version"]]),
]:
    vals = getter(json.load(open(os.path.join(root, rel))))
    if any(v != base_ver for v in vals):
        mismatches.append(f"{rel} ({vals} != {base_ver})")
for sp in sorted(glob.glob(os.path.join(root, "skills", "*", "SKILL.md"))):
    m = re.search(r'^\s*version:\s*"([^"]+)"', open(sp).read(), re.M)
    v = m.group(1) if m else None
    if v != base_ver:
        mismatches.append(f"{os.path.relpath(sp, root)} ({v} != {base_ver})")
if mismatches:
    for item in mismatches:
        print(f"  [VERSION MISMATCH] {item}", file=sys.stderr)
    sys.exit(1)
PY
then
  ERRORS=$((ERRORS + 1))
fi

if [[ "$CHECK_ONLY" == "false" && -n "$TARGET_DIR" ]]; then
  if [[ "$TARGET_DIR" == "$PLUGIN_ROOT" ]]; then
    echo "[ERROR] Refusing to link generated agent folders into the plugin source repository itself." >&2
    exit 2
  fi

  link_or_copy() {
    local src="$1"
    local dst="$2"
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    if [[ "$USE_COPY" == "true" ]]; then
      cp -R "$src" "$dst"
    else
      ln -s "$src" "$dst"
    fi
  }

  echo "[Sync] Linking Fluctseed entries non-destructively into $TARGET_DIR..."
  for skill in "${CORE_SKILLS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.agents/skills/$skill"
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.agent/skills/$skill"
  done
  for persona in "${PERSONAS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/agents/${persona}.md" "$TARGET_DIR/.claude/agents/${persona}.md"
    link_or_copy "$PLUGIN_ROOT/agents/${persona}.md" "$TARGET_DIR/.agent/agents/${persona}.md"
  done
  for rule in "${CORE_RULES[@]}"; do
    link_or_copy "$PLUGIN_ROOT/rules/${rule}.md" "$TARGET_DIR/.claude/rules/${rule}.md"
    link_or_copy "$PLUGIN_ROOT/rules/${rule}.md" "$TARGET_DIR/.agent/rules/${rule}.md"
  done
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "[FAIL] Bundle check failed with $ERRORS error(s)." >&2
  exit 1
fi

echo "[PASS] Fluctseed plugin bundle verified."
