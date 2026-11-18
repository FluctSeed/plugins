---
name: verification-harness
description: Build and maintain a deterministic end-to-end behavioral verification harness and user-POV feature map when a repository lacks scripted application verification.
---

# Behavioral Verification Harness & Feature Map

Use this tactic when a repository (or module) has no scripted end-to-end way to prove real user-observable behavior on its primary surface (web UI, CLI/TUI, HTTP/gRPC API, desktop, or library).

## 1. Discover the Real Surface

Inspect the repository before asking the developer:
- **Surface:** Primary user-facing interface (web UI, CLI/TUI, API service, worker, library).
- **Launch & Readiness:** Exact dev/build command, required env vars, migrations, seed data, and the concrete readiness signal (listening socket, health response after init completion, or CLI binary path).
- **Driver:** Reuse existing Playwright/Cypress/pytest/curl/PTY harnesses first; otherwise select the simplest deterministic driver (headless browser/CDP for web, PTY/tmux for TUI/CLI, HTTP client for APIs).
- **Isolation:** Determine whether parallel instances can isolate ports and data directories. If shared state prevents concurrent runs, enforce single-instance locking rather than corrupting developer sessions.

## 2. Assemble the 5-Part Verification Harness

Document or script five repeatable operations (in `<CONDUCTOR_DIR>/workflow.md` or a project-local `scripts/verify-e2e.*` helper):
1. **Launch:** Cold-start from an empty temporary data directory through readiness.
2. **Doctor:** Fast read-only check confirming process health, build version, port ownership, and auth state.
3. **Drive:** Exercise real user paths using stable selectors, routes, or CLI flags rather than internal test-only setters.
4. **Evidence:** Capture observable responses AND side effects (persisted rows, emitted files, exit codes, logs) into `<TRACK_DIR>/verification.log`.
5. **Cleanup:** Terminate only processes started by the run (by PID, never `killall` by name) and remove temporary scratch directories while keeping captured proof artifacts intact.

## 3. Seed & Maintain the Feature Map

For applications with multiple user journeys, maintain a concise feature map (in `README.md` contracts or `conductor/` docs) covering the top 3 to 5 critical flows:
- `Entry Point (User POV)`
- `Driving Command / Steps`
- `Observable End State & Side Effects`
- `Known Preconditions / Gotchas`

## 4. Prove & Maintain the Harness

- Execute the full `Launch -> Doctor -> Drive -> Evidence -> Cleanup` loop end-to-end at least once before relying on it, confirming cleanup leaves proof logs intact and strands zero background processes.
- When subsequent tracks modify routes, flags, or schemas, update the harness and feature map in the same wave (`principle-migrate-callers-then-delete-legacy-apis`) and distinguish genuine regressions from harness drift.
