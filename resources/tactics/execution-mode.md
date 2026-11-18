---
name: execution-mode
description: Phase 2 empirical implementation discipline for concise responses, scoped subagents, direct prose, minimal diffs, and runtime-verified code.
---

# Empirical Execution Mode

 Bundled tactics live in `resources/tactics/`, playbooks in `resources/playbooks/`, and principles in `resources/principles/`. Pass this file's resolved path to every delegated `implementer` worker.

## Non-Negotiables

Cite each `principle-*` file (`resources/principles/principle-*.md`) that shaped a design or implementation choice in your final summary.

- **First message on an implementation task**: State in your own words the user's goal, the problem being solved, and the smallest code change expected to meet it. If codebase evidence rules out the requested approach, present the evidence and stop.
- **Multi-session resumption & subsystem explanation**: Use `resources/tactics/recall.md` to reconstruct recent workspace and track state, and `resources/tactics/teach.md` when explaining how and why a subsystem works.
- **Empirical before `AskQuestion`**: If a fork can be settled by reading code (`resources/tactics/how.md`, `why.md`) or running a quick prototype (`resources/playbooks/prototype.md`), test it yourself instead of asking the human. Reserve questions for product intent or architectural trade-offs (`Author Decides Architecture`).
- **Any stateful logic**: Name the domain data shape first (`principle-model-the-domain`) and concentrate validation at system boundaries (`principle-boundary-discipline`). For concurrency races, retry loops, state machines, or parsers, apply `resources/tactics/formal-verification.md`.
- **Unscripted application surfaces**: When a service or UI lacks deterministic end-to-end verification, assemble a `Launch -> Doctor -> Drive -> Evidence -> Cleanup` loop via `resources/tactics/verification-harness.md`.
- **Cross-boundary design**: Sketch competing shapes via `resources/tactics/architect.md` and `resources/tactics/arena.md` before locking in code.
- **Parallel fan-out**: Use `resources/tactics/swarm.md` for independent slices and `resources/tactics/interrogate.md` for adversarial defect hunting.
- **Multi-step tracks**: Maintain the Throughput Checkpoint in `plan.md` (`resources/playbooks/feature.md`).
- **Prose and code hygiene**: Follow `resources/tactics/unslop.md`, `resources/tactics/technical-writing.md`, and `resources/tactics/no-comments.md` (verified by `agents/comment-auditor.md`).
- **Performance claims**: Apply `resources/principles/principle-explain-the-number.md` and `resources/tactics/benchmark-checklist.md` before reporting or acting on any latency or throughput measurement.
- **PR status / triage / shipping**: Follow `resources/playbooks/babysit.md`, `resources/templates/bugbot-triage.md`, and `resources/playbooks/shipping.md`.
- **Audit trail**: Log decisions, pivots, and verification proofs in `<TRACK_DIR>/decisions.tsv` (`resources/tactics/show-me-your-work.md`) and `<TRACK_DIR>/verification.log` (`scripts/capture-verify-log.sh`).

## Principles Index

Read the corresponding `resources/principles/principle-<slug>.md` file whenever applying a principle:

**Core**
- **Laziness Protocol** (`principle-laziness-protocol`): Bias toward deletion and the smallest diff that solves the problem.
- **Foundational Thinking** (`principle-foundational-thinking`): Define core types, sequencing, and shared state before writing control flow.
- **Redesign from First Principles** (`principle-redesign-from-first-principles`): Integrate new requirements as if foundational from day one rather than bolting on patches.
- **Attack the Premise** (`principle-attack-the-premise`): When two fixes sharing a premise fail, test the premise directly.
- **Subtract Before You Add** (`principle-subtract-before-you-add`): Remove dead weight first, then build on the simpler base.
- **Minimize Reader Load** (`principle-minimize-reader-load`): Collapse single-caller wrappers and shrink mutable scope.
- **Outcome-Oriented Execution** (`principle-outcome-oriented-execution`): Converge on the target architecture without keeping throwaway compatibility shims.
- **Experience First** (`principle-experience-first`): Prioritize caller and user ergonomics over internal implementation convenience.
- **Exhaust the Design Space** (`principle-exhaust-the-design-space`): Compare 2 to 3 distinct designs on novel architectural boundaries before committing.
- **Build the Lever** (`principle-build-the-lever`): Build deterministic verification scripts or codemods that reviewers can rerun.

**Architecture**
- **Model the Domain** (`principle-model-the-domain`): Encode domain invariants in types, state machines, or tables rather than scattered conditionals.
- **Boundary Discipline** (`principle-boundary-discipline`): Validate untrusted inputs at boundaries; keep internal logic pure.
- **Type System Discipline** (`principle-type-system-discipline`): Make illegal states unrepresentable.
- **Make Operations Idempotent** (`principle-make-operations-idempotent`): Ensure scripts and lifecycle steps converge cleanly across retries.
- **Migrate Callers Then Delete Legacy APIs** (`principle-migrate-callers-then-delete-legacy-apis`): Migrate callers and remove legacy paths in one wave.
- **Separate Before Serializing Shared State** (`principle-separate-before-serializing-shared-state`): Eliminate shared mutable state before adding locks.

**Verification**
- **Prove It Works** (`principle-prove-it-works`): Verify against the real runtime surface rather than a proxy or compilation check alone.
- **Fix Root Causes** (`principle-fix-root-causes`): Trace symptoms to the first point of divergence using runtime evidence.
- **Sequence Verifiable Units** (`principle-sequence-verifiable-units`): Decompose work into small steps that each end in an executable check.
- **Test Behavior, Not Implementation** (`principle-test-behavior-not-implementation`): Assert caller-observable behavior rather than internal mock wiring.
- **Explain the Number** (`principle-explain-the-number`): Identify physical/system limits and rule out measurement artifacts before reporting metrics.

**Delegation & Meta**
- **Guard the Context Window** (`principle-guard-the-context-window`): Delegate bulk exploration or isolated slices to subagents and keep concise syntheses in the main thread.
- **Never Block on the Human** (`principle-never-block-on-the-human`): Proceed autonomously on reversible steps within the approved spec and plan.
- **Encode Lessons in Structure** (`principle-encode-lessons-in-structure`): Turn recurring rules into scripts, schema checks, or linters rather than prose reminders.

## Autonomy & Safety Boundaries

- **Proceed without asking** on reversible local work inside the approved `spec.md` and `plan.md` (reading files, editing scoped code, running local builds and tests).
- **Always pause for human confirmation** before irreversible or external actions: force-pushes, branch deletions, production deployments, data deletion, external chat/email messages, external issue-tracker mutations, or changes to `spec.md`, `plan.md` task structure, `tech-stack.md`, or `security-policy.md`.
- **Candor over agreement**: Push back with concrete evidence when an approach violates invariants or adds unnecessary complexity.

## Subagent Delegation

- **Implementation delegates**: Spawn `implementer` (`invoke_subagent` `implementer` in Antigravity, `Agent` `fluctseed:implementer` in Claude Code, or `spawn_agent` reading `agents/implementer.md` in Codex CLI). Use the harness's inherited/configured model unless the user requests a specific tier.
- **Fresh subagents by default**: Give each new task or fix round to a fresh subagent with consolidated scope (`spec.md`, `plan.md` slice, prior findings, and target files). Resume an existing subagent only when it holds live process or worktree state costly to recreate.
- **Parent ownership**: Inspect every subagent's diff and verification output yourself before marking a task complete.

## Writing Style

- Use short declarative sentences.
- Do not use em-dashes or promotional filler (`resources/tactics/unslop.md`).
