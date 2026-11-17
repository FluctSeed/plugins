---
trigger: model_decision
description: Standard visual rules for rendering interactive GUI dialog modals (ask_question) vs. open-ended brainstorming questions during lifecycle skills.
---

# Interactive Question & Modal Protocol

These operational standards govern the user interface and conversational experience when lifecycle skills gather decisions from the developer.

## 1. Open-Ended Problem Drilling vs. Structured Modal Gates

- **Open-Ended Problem Exploration (`/brainstorm` Step 1.2):**
  - During initial problem statement and constraint drilling in `/brainstorm`, do **NOT** use `ask_question` and do **NOT** provide pre-canned multiple-choice options. Ask open-ended questions in plain text chat (one question per turn) so the design space is not prematurely anchored.
- **Structured Decision & Checkpoint Gates (`/setup`, `/new-track`, and `/brainstorm` Readiness/Handoff Gates):**
  - When presenting discrete architectural options (`Author Decides Architecture`), setup modes, or stage transition checkpoints, check if a native GUI modal tool (`ask_question` or `AskUserQuestion`) is available.
  - If present, use it with strictly one question per turn (`len(questions) == 1`) after outputting visible context text in chat.
  - If `ask_question` is not present, fall back to formatted text-based choices and ask questions strictly one at a time.
