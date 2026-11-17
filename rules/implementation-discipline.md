---
trigger: always_on
description: Engineering discipline rules for empirical root-cause investigation, domain modeling, minimal diffs, real verification, and decision logging.
---

# Empirical Implementation & Verification Rules

1. **Restate Goal & Smallest Change:** On implementation tasks, state in your own words the user's goal, the problem being solved, and the smallest change expected to meet it.
2. **Empirical Over Speculative (`Classify before AskQuestion`):** Never ask the human a question that an experiment or codebase trace (`resources/tactics/how.md`, `why.md`, `resources/playbooks/prototype.md`) can answer.
3. **Model the Domain First (`principle-model-the-domain`):** Before writing logic, name the data shape and encode the domain in types, state machines, or tables rather than scattered booleans and conditionals. Concentrate validation at system boundaries (`principle-boundary-discipline`, `principle-type-system-discipline`).
4. **Reproduce & Fix Root Causes (`principle-fix-root-causes`):** When fixing a bug, reproduce it on the matching surface first. Trace the symptom back to the first place the system went wrong using runtime evidence. Never ship a speculative guard that hides an invalid state.
5. **Laziness Protocol & Subtract Before You Add:** Bias toward deletion and the smallest diff that solves the problem. Remove dead weight first, collapse one-caller wrappers (`principle-minimize-reader-load`), and never keep throwaway compatibility layers (`principle-migrate-callers-then-delete-legacy-apis`).
6. **Prove It Works (`principle-prove-it-works`):** Verify every task against the real artifact, not a proxy or "it compiles." Record actual test/build commands and outputs in `conductor/tracks/<id>/verification.log` via `./scripts/capture-verify-log.sh`.
7. **Decision Trail (`show-me-your-work`):** Log every significant engineering decision, pivot, and completed task verification in `conductor/tracks/<id>/decisions.tsv` using `./scripts/log.sh`. The log is append-only; supersede wrong calls with a new row rather than editing history.
8. **Zero Slop & Zero Narrating Comments (`unslop` & `no-comments`):** Write short declarative sentences with no em-dashes and no mid-sentence colons. Keep code comments only for non-obvious *why* constraints that code cannot express; strip phase-narrating comments via `agents/comment_auditor.md`.
