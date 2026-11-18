---
trigger: model_decision
description: Cross-harness interactive question rules across Antigravity (ask_question), Claude Code (AskUserQuestion), and Codex CLI (request_user_input or plain-text fallback).
---

# Interactive Question & Modal Protocol

These standards govern how lifecycle skills gather human decisions across different AI coding harnesses.

## 1. Open-Ended Problem Drilling vs. Structured Decision Gates

- **Open-Ended Problem Exploration (`brainstorm` Step 1.2)**
  - During initial problem statement and constraint drilling in `brainstorm`, do **not** call any structured multiple-choice modal tool and do **not** supply pre-canned candidate answers. Ask one open-ended plain-text question per turn so the design space is not prematurely anchored.
- **Structured Decision & Checkpoint Gates (`setup`, `new-track`, `review`, `revert`, and `brainstorm` Readiness/Handoff Gates)**
  - Write any deliverable artifact (`concepts_brief.md`, `spec.md`, `plan.md`, `design_audit_report.md`) to disk **before** asking the gate question, and output concise context with a clickable file link in chat.
  - Ask strictly **one question per turn** using your active harness's native schema below. Never pass another harness's JSON field names to your tool.

## 2. Harness-Native Question Tool Mapping

1. **Google Antigravity (`ask_question`)**
   - Pass `questions` (length 1) with `question` (string), `options` (array of unnumbered option strings; prefix the recommended first option with `(Recommended)` when a clear recommendation exists; omit `"Other"` as the UI adds it), and `is_multi_select` (boolean).
2. **Claude Code (`AskUserQuestion`)**
   - Pass `questions` (length 1) with `header` (short label <= 12 chars), `question` (string), `multiSelect` (boolean), and `options` (2 to 4 objects of `{label, description}`; omit `"Other"` as Claude Code provides custom input automatically).
3. **OpenAI Codex CLI (`request_user_input` or Plain-Text Fallback)**
   - In Codex **Plan mode**, call `request_user_input` with `questions` (length 1) containing `{id, header, question, options: [{label, description}]}`.
   - In Codex **default execution mode** (where `request_user_input` is unavailable) or any harness without a modal tool, output a numbered single-question list in plain text chat (including an `"Other"` free-form option) and end your turn to wait for the developer's reply.
