---
name: teach
description: Explain how a subsystem or change works and why it was built that way by combining empirical code tracing (how) and git/record archaeology (why) into progressive, diagram-built plain prose.
---

# Teach

Explain what a subsystem or change is, how it works today, and why it is shaped that way so an engineer genuinely understands it without reading filler.

## Execution Steps

1. **Run `how` and `why` First:** Trace the live code path (`resources/tactics/how.md`) and commit/PR history (`resources/tactics/why.md`) in parallel when explaining a non-trivial subsystem. Preserve `why`'s distinction between documented record and inference.
2. **Lead with a Plain 2-Sentence Definition:** State what the mechanism is and what problem it solves in concrete terms before listing files or symbols. Match depth to the caller's goal (debugging, reviewing, or extending).
3. **Build Diagrams Progressively:** For flows with 3 or more moving parts, do not dump one giant all-at-once diagram at the end. Build understanding across 2 to 3 incremental `mermaid` diagrams where each step adds one new interaction or failure edge.
4. **Cut Meta-Labels & Slop:** Follow `resources/tactics/unslop.md`. Do not print theatrical headers (`"The key insight"`, `"Pause here"`, `"TL;DR"`). State mechanisms directly in short declarative sentences without em-dashes.
