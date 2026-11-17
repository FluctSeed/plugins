#!/usr/bin/env bash
# ==============================================================================
# Fluctseed Cross-Platform Agent Synchronizer (sync-agents.sh)
# Maps the open-standard core across:
#   1. Claude Code        (.claude/, CLAUDE.md, .claude-plugin/)
#   2. OpenAI Codex CLI   (.agents/, .codex/, AGENTS.md, .codex-plugin/)
#   3. Antigravity (agy)  (.agent/, .gemini/, ~/.gemini/config/plugins/fluctseed)
#   4. Grok (CLI / API)   (.grok/, .grok/GROK.md, .grok/fluctseed-tools.json)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR="$PLUGIN_ROOT"
INSTALL_GLOBAL=false
CHECK_ONLY=false
USE_COPY=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --target <dir>   Target project directory to map agent configs into (default: plugin root)
  --global         Also sync into user global agent directories (~/.claude, ~/.codex, ~/.gemini, ~/.grok)
  --copy           Copy files instead of creating symlinks
  --check          Verify all core assets and 4-platform mappings
  -h, --help       Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$(cd "$2" && pwd)"
      shift 2
      ;;
    --global)
      INSTALL_GLOBAL=true
      shift
      ;;
    --copy)
      USE_COPY=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
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
PERSONAS=("zoom_out" "inventive_catalyst" "comprehension" "design_critic" "structural" "style" "implementation_readiness" "codebase_details" "synthesizer" "bootstrap_orchestrator" "implementer" "comment_auditor")

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

echo "================================================================================"
echo "[Fluctseed] Cross-Platform AI Engineering Plugin Sync"
echo "  Plugin Source : $PLUGIN_ROOT"
echo "  Target Project: $TARGET_DIR"
echo "  Global Install: $INSTALL_GLOBAL"
echo "================================================================================"

chmod +x "$PLUGIN_ROOT/scripts/resume.py" \
         "$PLUGIN_ROOT/scripts/gate_check.py" \
         "$PLUGIN_ROOT/scripts/prepare_audit_context.py" \
         "$PLUGIN_ROOT/scripts/log.sh" \
         "$PLUGIN_ROOT/scripts/capture-verify-log.sh" \
         "$PLUGIN_ROOT/scripts/check-plan.mjs" \
         "$PLUGIN_ROOT/scripts/worktree-audit.sh" \
         "$PLUGIN_ROOT/skills/setup/scripts/resume.py" 2>/dev/null || true

if [[ "$CHECK_ONLY" == "false" ]]; then
  if [[ "$TARGET_DIR" != "$PLUGIN_ROOT" ]]; then
    link_or_copy "$PLUGIN_ROOT/resources" "$TARGET_DIR/resources"
    link_or_copy "$PLUGIN_ROOT/scripts" "$TARGET_DIR/scripts"
    cp "$PLUGIN_ROOT/AGENTS.md" "$TARGET_DIR/AGENTS.md"
  fi

  # ----------------------------------------------------------------------------
  # 1. Claude Code Mapping (.claude/ & CLAUDE.md)
  # ----------------------------------------------------------------------------
  echo "[1/4] Syncing Claude Code (.claude/skills, .claude/agents, .claude/rules, CLAUDE.md)..."
  rm -rf "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/rules"
  mkdir -p "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/rules"

  for skill in "${CORE_SKILLS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.claude/skills/$skill"
  done

  for agent_file in "$PLUGIN_ROOT/.claude-plugin/agents/"*.md; do
    link_or_copy "$agent_file" "$TARGET_DIR/.claude/agents/$(basename "$agent_file")"
  done

  for rule_file in "$PLUGIN_ROOT/rules/"*.md; do
    link_or_copy "$rule_file" "$TARGET_DIR/.claude/rules/$(basename "$rule_file")"
  done

  if [[ ! -f "$TARGET_DIR/CLAUDE.md" ]]; then
    ln -s "AGENTS.md" "$TARGET_DIR/CLAUDE.md"
  fi

  # ----------------------------------------------------------------------------
  # 2. OpenAI Codex CLI & Open Agent Skills Standard (.agents/ & .codex/)
  # ----------------------------------------------------------------------------
  echo "[2/4] Syncing OpenAI Codex CLI & Open Standard (.agents/skills, .codex/skills, .agents/plugins)..."
  rm -rf "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.codex/skills" "$TARGET_DIR/.codex/rules"
  mkdir -p "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.agents/plugins" "$TARGET_DIR/.codex/skills" "$TARGET_DIR/.codex/rules"

  for skill in "${CORE_SKILLS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.agents/skills/$skill"
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.codex/skills/$skill"
  done

  for rule_file in "$PLUGIN_ROOT/rules/"*.md; do
    link_or_copy "$rule_file" "$TARGET_DIR/.codex/rules/$(basename "$rule_file")"
  done

  cat > "$TARGET_DIR/.agents/plugins/marketplace.json" <<EOF
{
  "name": "fluctseed",
  "plugins": [
    {
      "name": "fluctseed",
      "description": "Spec-Driven and Empirical AI Engineering Platform",
      "version": "2.1.0",
      "path": "../../"
    }
  ]
}
EOF

  # ----------------------------------------------------------------------------
  # 3. Google Antigravity (agy) Mapping (.agent/ & .gemini/)
  # ----------------------------------------------------------------------------
  echo "[3/4] Syncing Google Antigravity (.agent/skills, .agent/rules, .agent/agents, .gemini/skills)..."
  rm -rf "$TARGET_DIR/.agent/skills" "$TARGET_DIR/.agent/rules" "$TARGET_DIR/.agent/agents" "$TARGET_DIR/.gemini/skills" "$TARGET_DIR/.gemini/rules"
  mkdir -p "$TARGET_DIR/.agent/skills" "$TARGET_DIR/.agent/rules" "$TARGET_DIR/.agent/agents" "$TARGET_DIR/.gemini/skills" "$TARGET_DIR/.gemini/rules"

  for skill in "${CORE_SKILLS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.agent/skills/$skill"
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.gemini/skills/$skill"
  done

  for rule_file in "$PLUGIN_ROOT/rules/"*.md; do
    link_or_copy "$rule_file" "$TARGET_DIR/.agent/rules/$(basename "$rule_file")"
    link_or_copy "$rule_file" "$TARGET_DIR/.gemini/rules/$(basename "$rule_file")"
  done

  for agent_file in "$PLUGIN_ROOT/agents/"*.md; do
    link_or_copy "$agent_file" "$TARGET_DIR/.agent/agents/$(basename "$agent_file")"
  done

  # ----------------------------------------------------------------------------
  # 4. Grok (CLI / API Agent) Mapping (.grok/ & .grok/fluctseed-tools.json)
  # ----------------------------------------------------------------------------
  echo "[4/4] Syncing Grok CLI & API Agent (.grok/skills, .grok/agents, .grok/GROK.md, .grok/fluctseed-tools.json)..."
  rm -rf "$TARGET_DIR/.grok/skills" "$TARGET_DIR/.grok/agents" "$TARGET_DIR/.grok/rules"
  mkdir -p "$TARGET_DIR/.grok/skills" "$TARGET_DIR/.grok/agents" "$TARGET_DIR/.grok/rules"

  for skill in "${CORE_SKILLS[@]}"; do
    link_or_copy "$PLUGIN_ROOT/skills/$skill" "$TARGET_DIR/.grok/skills/$skill"
  done

  for agent_file in "$PLUGIN_ROOT/agents/"*.md; do
    link_or_copy "$agent_file" "$TARGET_DIR/.grok/agents/$(basename "$agent_file")"
  done

  for rule_file in "$PLUGIN_ROOT/rules/"*.md; do
    link_or_copy "$rule_file" "$TARGET_DIR/.grok/rules/$(basename "$rule_file")"
  done

  link_or_copy "$PLUGIN_ROOT/AGENTS.md" "$TARGET_DIR/.grok/GROK.md"

  python3 - "$PLUGIN_ROOT" "$TARGET_DIR/.grok/fluctseed-tools.json" << 'PYEOF'
import json, sys

plugin_root, out_path = sys.argv[1], sys.argv[2]
skills_meta = [
    ("setup", "Initialize repository with project context docs, enterprise security policy, workflow standard, and directory README.md architecture contracts."),
    ("brainstorm", "Conduct multi-turn open-ended problem drilling and parallel 7-lens fresh-context brainstorm critique (Mode BRAINSTORM) to produce concepts_brief.md."),
    ("new_track", "Ingest concepts_brief.md, draft spec.md and plan.md for a track, run zero-context 5-stage subagent cross-verification, resolve findings, and lock Stage 3 Human Gate."),
    ("implement", "Verify Stage 3 Human Gate lock and execute plan.md tasks under engineering playbooks, behavioral TDD, verification.log capture, and decisions.tsv logging."),
    ("review", "Run Stage 5 Triple Verification (runtime proof & deslop/no-comments, spec/contract drift report, style/security review) and open a Git PR."),
    ("status", "Display unified dashboard of tracks, active Phase, zero-context design audit status, Human Gate lock, and decisions.tsv/verification.log."),
    ("revert", "Safely revert Git commits for a logical unit (Track, Phase, or Task) and append an auditable superseding entry to decisions.tsv."),
]

tools = []
for name, desc in skills_meta:
    folder = name.replace("_", "-")
    tools.append({
        "type": "function",
        "function": {
            "name": f"fluctseed_{name}",
            "description": desc,
            "parameters": {
                "type": "object",
                "properties": {
                    "track_id": {
                        "type": "string",
                        "description": "Optional track ID or target path."
                    },
                    "user_input": {
                        "type": "string",
                        "description": "Task description, arguments, or confirmation response."
                    }
                },
                "required": []
            },
            "x_skill_path": f"skills/{folder}/SKILL.md"
        }
    })

tools.append({
    "type": "function",
    "function": {
        "name": "spawn_fresh_context_subagent",
        "description": "Spawn a zero-context design reviewer or implementation/hygiene subagent with fresh conversation history.",
        "parameters": {
            "type": "object",
            "properties": {
                "persona": {
                    "type": "string",
                    "enum": [
                        "zoom_out", "inventive_catalyst", "comprehension",
                        "design_critic", "structural", "style",
                        "implementation_readiness", "codebase_details",
                        "synthesizer", "bootstrap_orchestrator",
                        "implementer", "comment_auditor"
                    ]
                },
                "target_file": {"type": "string"},
                "standard": {"type": "string"},
                "audit_context": {
                    "type": "array",
                    "items": {"type": "string"}
                }
            },
            "required": ["persona", "target_file"]
        },
        "x_agents_dir": "agents/"
    }
})

with open(out_path, "w", encoding="utf-8") as f:
    json.dump({"platform": "grok-cli-api", "version": "2.1.0", "tools": tools}, f, indent=2)
    f.write("\n")
PYEOF

  if [[ "$INSTALL_GLOBAL" == "true" ]]; then
    echo "[Global] Installing into user home directories (~/.claude, ~/.codex, ~/.agents, ~/.gemini, ~/.grok)..."
    mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents" "$HOME/.claude/rules" \
             "$HOME/.codex/skills" "$HOME/.codex/rules" \
             "$HOME/.agents/skills" \
             "$HOME/.gemini/config/plugins" \
             "$HOME/.grok/skills" "$HOME/.grok/agents" "$HOME/.grok/rules"

    for skill in "${CORE_SKILLS[@]}"; do
      link_or_copy "$PLUGIN_ROOT/skills/$skill" "$HOME/.claude/skills/$skill"
      link_or_copy "$PLUGIN_ROOT/skills/$skill" "$HOME/.codex/skills/$skill"
      link_or_copy "$PLUGIN_ROOT/skills/$skill" "$HOME/.agents/skills/$skill"
      link_or_copy "$PLUGIN_ROOT/skills/$skill" "$HOME/.grok/skills/$skill"
    done

    for agent_file in "$PLUGIN_ROOT/.claude-plugin/agents/"*.md; do
      link_or_copy "$agent_file" "$HOME/.claude/agents/$(basename "$agent_file")"
    done

    for agent_file in "$PLUGIN_ROOT/agents/"*.md; do
      link_or_copy "$agent_file" "$HOME/.grok/agents/$(basename "$agent_file")"
    done

    for rule_file in "$PLUGIN_ROOT/rules/"*.md; do
      link_or_copy "$rule_file" "$HOME/.claude/rules/$(basename "$rule_file")"
      link_or_copy "$rule_file" "$HOME/.codex/rules/$(basename "$rule_file")"
      link_or_copy "$rule_file" "$HOME/.grok/rules/$(basename "$rule_file")"
    done

    link_or_copy "$PLUGIN_ROOT/AGENTS.md" "$HOME/.grok/GROK.md"
    cp "$TARGET_DIR/.grok/fluctseed-tools.json" "$HOME/.grok/fluctseed-tools.json"

    AGY_PLUGIN_DEST="$HOME/.gemini/config/plugins/fluctseed"
    if [[ ! -e "$AGY_PLUGIN_DEST" ]] || [[ "$(cd "$AGY_PLUGIN_DEST" 2>/dev/null && pwd -P)" != "$(cd "$PLUGIN_ROOT" && pwd -P)" ]]; then
      link_or_copy "$PLUGIN_ROOT" "$AGY_PLUGIN_DEST"
    fi
  fi
fi

# ==============================================================================
# Verification & Integrity Check
# ==============================================================================
echo "--------------------------------------------------------------------------------"
echo "[Verify] Running Cross-Platform Integrity Audit..."

ERRORS=0
check_path() {
  if [[ ! -e "$1" ]]; then
    echo "  [MISSING] $1" >&2
    ERRORS=$((ERRORS + 1))
  fi
}

for skill in "${CORE_SKILLS[@]}"; do
  check_path "$PLUGIN_ROOT/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.claude/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.agents/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.codex/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.agent/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.gemini/skills/$skill/SKILL.md"
  check_path "$TARGET_DIR/.grok/skills/$skill/SKILL.md"
done

for persona in "${PERSONAS[@]}"; do
  check_path "$PLUGIN_ROOT/agents/${persona}.md"
  check_path "$TARGET_DIR/.claude/agents/${persona}.md"
  check_path "$TARGET_DIR/.agent/agents/${persona}.md"
  check_path "$TARGET_DIR/.grok/agents/${persona}.md"
done

for rule in lifecycle-workflow design-audit-discipline implementation-discipline interactive-questions; do
  check_path "$PLUGIN_ROOT/rules/${rule}.md"
  check_path "$TARGET_DIR/.claude/rules/${rule}.md"
  check_path "$TARGET_DIR/.codex/rules/${rule}.md"
  check_path "$TARGET_DIR/.agent/rules/${rule}.md"
  check_path "$TARGET_DIR/.grok/rules/${rule}.md"
done

check_path "$TARGET_DIR/CLAUDE.md"
check_path "$TARGET_DIR/AGENTS.md"
check_path "$TARGET_DIR/.grok/GROK.md"
check_path "$TARGET_DIR/.grok/fluctseed-tools.json"
check_path "$TARGET_DIR/.agents/plugins/marketplace.json"

PLAYBOOK_COUNT=$(find "$PLUGIN_ROOT/resources/playbooks" -name "*.md" | wc -l | tr -d ' ')
PRINCIPLE_COUNT=$(find "$PLUGIN_ROOT/resources/principles" -name "*.md" | wc -l | tr -d ' ')
STANDARD_COUNT=$(find "$PLUGIN_ROOT/resources/standards" -name "*.md" | wc -l | tr -d ' ')
STYLEGUIDE_COUNT=$(find "$PLUGIN_ROOT/resources/styleguides" -name "*.md" | wc -l | tr -d ' ')
TACTIC_COUNT=$(find "$PLUGIN_ROOT/resources/tactics" -name "*.md" | wc -l | tr -d ' ')

echo "  - Lifecycle Skills        : ${#CORE_SKILLS[@]} (/setup, /brainstorm, /new-track, /implement, /review, /status, /revert)"
echo "  - Subagent Personas       : ${#PERSONAS[@]}"
echo "  - Design Review Standards : $STANDARD_COUNT"
echo "  - Code Style Guides       : $STYLEGUIDE_COUNT"
echo "  - Engineering Playbooks   : $PLAYBOOK_COUNT"
echo "  - Engineering Principles  : $PRINCIPLE_COUNT"
echo "  - Tactical Protocols      : $TACTIC_COUNT"
echo "  - Platforms Verified      : Claude Code, OpenAI Codex CLI, Antigravity (agy), Grok (CLI/API)"

if [[ "$ERRORS" -gt 0 ]]; then
  echo "[FAILED] $ERRORS missing paths detected." >&2
  exit 1
fi

echo "[SUCCESS] All core assets and 4-platform mappings verified with 0 errors."
echo "================================================================================"
