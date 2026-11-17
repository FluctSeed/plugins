# Enterprise Security Policy (`security-policy.md`)

This document defines the mandatory security invariants for this repository. Both **Zero-Context Design Reviewers** (during `/new-track`) and **Code Reviewers** (during `/implement` and `/review`) treat violations of this policy as **Blocker / Critical** severity.

## 1. Secrets & Credential Hygiene
- **Zero Hardcoded Secrets:** API keys, private keys, tokens, passwords, and connection strings must never appear in source code, test fixtures, or committed configuration files.
- **Environment Isolation:** Load secrets exclusively from environment variables or approved secret managers at system boundaries.

## 2. Boundary Validation & Input Safety (`Boundary Discipline`)
- **Parse, Don't Validate at Boundaries:** All external inputs (HTTP payloads, CLI args, webhook bodies, file uploads, environment configs, LLM outputs) must be parsed and schema-validated at the entry boundary before reaching domain logic.
- **Injection Prevention:** Use parameterized queries for all database operations. Never interpolate unvalidated user input into shell commands, SQL, HTML templates, or file paths.

## 3. Authentication, Authorization & Data Privacy
- **Explicit Authz Checks:** Every state-mutating endpoint or RPC handler must explicitly verify caller identity and resource-level authorization invariants.
- **PII & Audit Redaction:** Never log raw passwords, session tokens, or unmasked PII in application logs, `decisions.tsv`, or `verification.log`.

## 4. Dependency & Supply-Chain Integrity
- **Minimal Dependencies:** Do not introduce new third-party dependencies unless explicitly documented and approved in `conductor/tech-stack.md` before implementation.
- **Lockfile Integrity:** Commit lockfile updates alongside manifest changes and verify no known high/critical CVEs are introduced.
