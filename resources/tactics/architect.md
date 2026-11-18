---
name: architect
description: Sketch types, signatures, and module boundaries before writing implementation logic, compare structurally distinct candidates, and implement against the chosen contract.
---

# Architect

Sketch types, function signatures, and module boundaries with stub bodies before writing implementation code. Compare at least two structurally distinct designs, synthesize the cleanest boundary, and implement against that contract.

## Workflow Phases

1. **Phase A (Ground)**: Trace every subsystem the change touches (`resources/tactics/how.md`) and existing rationale (`resources/tactics/why.md`). Skip only for pure greenfield code with no surrounding integration.
2. **Phase B (Sketch & Compare)**: Run `resources/tactics/arena.md` (or spawn 2 to 3 parallel read-only subagents using your harness's configured model) with this runner brief:
   - *Runner Prompt*: Write caller usage first, then derive minimal public types, signatures, error cases, and state transitions (`principle-exhaust-the-design-space`). Keep implementation bodies stubbed.
   - *Red-Flag Screen*: Reject candidates that leak internal representation across module boundaries, scatter boolean flags instead of modeling state, require callers to know call-ordering preconditions unexpressed in types, or introduce single-caller pass-through layers. Prefer deep modules (simple interface hiding internal complexity).
3. **Phase C (Checkpoint when Crossing Track Spec)**: Proceed directly if within approved `spec.md` boundaries; pause for `Author Decides Architecture` sign-off if public contracts or storage schemas change.
4. **Phase D (Implement)**: Replace stubs with implementation and behavioral tests. Treat friction against the sketch as a signal to inspect requirements rather than bolting on workarounds.
5. **Phase E (Scrap & Redesign if Needed)**: If repeated special-case branches, type casts (`any`), or unexpected locks accumulate across files, discard the sketch (`principle-redesign-from-first-principles`, `principle-subtract-before-you-add`) and re-run Phase B with the newly discovered constraints.

## Output Structure

Record the chosen sketch in `spec.md` (Phase 1) or `<TRACK_DIR>/decisions.tsv` (Phase 2):
- **Caller Usage Sketch**: Concrete call-site snippet.
- **Public Types & Signatures**: Boundary contracts and invariants.
- **Synthesis Rationale**: Why this shape beat the competing candidate(s).
