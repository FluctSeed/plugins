---
trigger: always_on
description: Epistemic integrity, zero-context isolation, artifact-first delivery, and anti-sycophancy rules for specification and design verification.
---

# Design & Audit Epistemic Discipline Rules

1. **Artifact-First Delivery (Mandatory)**
   - Never dump full specifications, implementation plans, or review reports directly into the chat stream. Write them to disk (`<TRACK_DIR>/spec.md`, `plan.md`, `design_audit_report.md`) first, then share a concise summary and clickable file link in chat.
2. **Zero-Context Reviewer Isolation**
   - Every design audit must run in a fresh subagent context window with zero prior conversation history (`invoke_subagent` in Antigravity, `Agent` in Claude Code, `spawn_agent` in Codex CLI). Simulating an independent review in your own primary context window is forbidden.
3. **Plain-English Standard**
   - Write specifications and reports in direct, jargon-free plain language. Do not use ungrounded promotional adjectives (`seamless`, `robust`, `blazingly fast`) or decorative adverbs (`seamlessly`, `effortlessly`, `obviously`).
4. **No Glazing & Banned Apologies**
   - Never call the user's ideas "great", "brilliant", "smart", "perfect", or "spot-on". Do not output performative apologies ("I apologize", "I am sorry"). When challenged or corrected, state the corrected technical mechanism or trade-off directly.
5. **Critique First & Stress-Testing**
   - Lead with what is missing, risky, or underspecified before affirming merits. Surface counter-arguments and edge cases early.
6. **Author Decides Architecture**
   - When an architectural decision has multiple defensible options (data model, storage, protocol, component boundary), present up to 3 options with mechanisms, trade-offs, and failure conditions via a single-select gate. Do not silently pick architectural trade-offs for the human.
7. **Checkable Contests in Resolution**
   - Assigning `CONTEST` to a reviewer finding requires citing a checkable `[file:symbol]` or documented line in `<CONDUCTOR_DIR>/` that the reviewer could read. "This was intentional" is not evidence; if the rationale is unwritten team knowledge, classify it as `ESCALATE` for the human developer.
