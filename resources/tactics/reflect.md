---
name: reflect
description: Audit the active workspace conversation transcript across three lenses (Judgment, Tooling, Divergent) and propose concrete rule or skill improvements for developer approval.
---

# Reflect

Extract durable engineering lessons from the current workspace session and propose targeted updates to project rules, `conductor/workflow.md`, or skills. Skip trivial one-off incidents.

## 1. Locate the Active Workspace Transcript

Read only the current workspace's session log; never scan unrelated project directories:
- **Antigravity**: `<appDataDir>/brain/<conversation-id>/.system_generated/logs/transcript.jsonl`
- **Claude Code**: `~/.claude/projects/<slug>/<session-id>.jsonl`
- **Codex CLI**: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` matching the current `cwd`
- If no transcript file is accessible, construct a concise factual digest of the current session's mistakes, pivots, and tool failures.

## 2. Parallel Three-Lens Review

Spawn three parallel read-only subagents (using your harness's subagent tool and configured model, or evaluate sequentially if subagents are unavailable) against the transcript/digest:

1. **Judgment Lens**: Identify wrong assumptions, premature questions that code tracing could have answered, missed root causes, or scope drift.
2. **Tooling & Script Lens**: Identify manual multi-step checks, brittle shell commands, or repeated errors that should be encoded as a deterministic script, linter, or gate check (`principle-encode-lessons-in-structure`).
3. **Divergent Lens**: Challenge whether the session solved the right problem or missed a simpler architectural path.

## 3. Synthesize & Gate Before Applying

Compile findings into three buckets (`Accepted Proposals`, `Structural Script/Lint Backlog`, `Rejected One-Offs`) showing exact target paths and diffs.

- **Mandatory Human Approval**: Never modify plugin cache files (`plugins/cache/`) and never auto-apply rule or skill edits without explicit developer confirmation. Present the proposed changes and apply only the subset approved by the developer.
