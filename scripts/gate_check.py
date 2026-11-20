#!/usr/bin/env python3
"""Enforces the Stage 3 Human Gate and Zero-Context Design Audit lock between /new-track and /implement.

Usage:
  python3 scripts/gate_check.py --status <track_id_or_path> [--conductor-dir <dir>]
  python3 scripts/gate_check.py --approve <track_id_or_path> [--approver <name>] [--skip-audit] [--conductor-dir <dir>]
  python3 scripts/gate_check.py --verify <track_id_or_path> [--conductor-dir <dir>]
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import subprocess
import sys

IGNORE_DIRS = {
    ".git", "node_modules", "dist", "build", "venv", ".venv",
    "vendor", "third_party", "target", "out", "coverage", "__pycache__",
    ".claude", ".codex", ".agent", ".agents", ".gemini", ".grok",
}


def detect_repo_root() -> str:
    try:
        p = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        )
        top = p.stdout.strip()
        if top and os.path.isdir(top):
            return top
    except Exception:
        pass
    return os.getcwd()


def detect_git_head() -> str:
    try:
        p = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True, text=True, check=True,
        )
        return p.stdout.strip()
    except Exception:
        return ""


def resolve_track_dir(target: str, conductor_dir: str = None) -> str:
    if os.path.isdir(target):
        return os.path.normpath(target)
    if conductor_dir:
        cand = os.path.join(conductor_dir, "tracks", target)
        if os.path.isdir(cand):
            return os.path.normpath(cand)
        raise FileNotFoundError(
            f"Track directory not found for '{target}' under conductor '{conductor_dir}'"
        )

    cwd_candidate = os.path.join("conductor", "tracks", target)
    if os.path.isdir(cwd_candidate):
        return os.path.normpath(cwd_candidate)

    repo_root = detect_repo_root()
    matches = []
    for root, dirs, _ in os.walk(repo_root, topdown=True):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".bazel")]
        if os.path.basename(root) == "tracks" and os.path.basename(os.path.dirname(root)) == "conductor":
            cand = os.path.join(root, target)
            if os.path.isdir(cand):
                matches.append(os.path.relpath(cand, os.getcwd()))

    if len(matches) == 1:
        return os.path.normpath(matches[0])
    if len(matches) > 1:
        raise ValueError(
            f"Ambiguous track '{target}' matched multiple monorepo modules ({', '.join(sorted(matches))}). "
            "Pass --conductor-dir <module>/conductor or the explicit track directory path."
        )
    raise FileNotFoundError(
        f"Track directory not found for '{target}' (checked './conductor/tracks/{target}' and monorepo modules)"
    )


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: str) -> str:
    if not os.path.isfile(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_plan_structure(path: str) -> str:
    """Hashes plan.md structure while normalizing checkbox state transitions, task SHAs, and phase [checkpoint: <sha>] stamps.
    Preserves [human-gate] markers on phase headings so gate tags cannot be silently added or removed after lock."""
    if not os.path.isfile(path):
        return ""
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    # Strip trailing Review Fixes phase appended during /review
    raw = re.split(r"^##\s+Phase:\s*Review Fixes\b", raw, maxsplit=1, flags=re.M)[0]

    normalized_lines = []
    for line in raw.splitlines():
        s = line.rstrip()
        if re.match(r"^##\s+Phase\b", s, flags=re.I):
            s = re.sub(r"\s*\[checkpoint:\s*`?[0-9a-f]{7,40}`?\]", "", s, flags=re.I).rstrip()
        m = re.match(r"^(\s*-\s*)\[[ ~xX]\](\s+.*)$", s)
        if m:
            body = re.sub(r"\s+`?[0-9a-f]{7,40}`?\s*$", "", m.group(2))
            s = f"{m.group(1)}[ ]{body}"
        normalized_lines.append(s)

    while normalized_lines and normalized_lines[-1] == "":
        normalized_lines.pop()

    return sha256_bytes(("\n".join(normalized_lines) + "\n").encode("utf-8"))


def load_metadata(track_dir: str) -> dict:
    meta_path = os.path.join(track_dir, "metadata.json")
    if os.path.exists(meta_path):
        with open(meta_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            if not isinstance(data, dict):
                raise ValueError("metadata.json root must be a JSON object")
            return data
    return {
        "track_id": os.path.basename(os.path.normpath(track_dir)),
        "type": "feature",
        "status": "draft",
        "phase_mode": "Phase 1 (Spec & Zero-Context Audit)",
        "design_audited": False,
        "human_gate_approved": False,
    }


def save_metadata(track_dir: str, meta: dict) -> None:
    meta_path = os.path.join(track_dir, "metadata.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
        f.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Stage 3 Human Gate Controller")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--status", metavar="TRACK", help="Inspect gate status for track")
    group.add_argument("--approve", metavar="TRACK", help="Record developer Human Gate approval and lock spec/plan hashes")
    group.add_argument("--verify", metavar="TRACK", help="Verify track is approved for Phase 2 (/implement)")
    parser.add_argument("--approver", default="developer", help="Approver identifier")
    parser.add_argument("--skip-audit", action="store_true", help="Explicitly approve without design_audit_report.md")
    parser.add_argument("--conductor-dir", default=None, help="Explicit path to conductor/ directory in a monorepo module")
    args = parser.parse_args()

    target = args.status or args.approve or args.verify
    try:
        track_dir = resolve_track_dir(target, conductor_dir=args.conductor_dir)
        meta = load_metadata(track_dir)
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2))
        return 1

    spec_path = os.path.join(track_dir, "spec.md")
    plan_path = os.path.join(track_dir, "plan.md")
    audit_path = os.path.join(track_dir, "design_audit_report.md")

    current_spec_hash = sha256_file(spec_path)
    current_plan_hash = sha256_file(plan_path)
    current_plan_struct_hash = sha256_plan_structure(plan_path)
    has_audit_report = os.path.isfile(audit_path) and os.path.getsize(audit_path) > 0

    if args.approve:
        if not current_spec_hash or not current_plan_hash or os.path.getsize(spec_path) == 0 or os.path.getsize(plan_path) == 0:
            print(json.dumps({
                "ok": False,
                "error": "Cannot approve Human Gate. Both spec.md and plan.md must exist and be non-empty.",
            }, indent=2))
            return 1
        if not has_audit_report and not args.skip_audit:
            print(json.dumps({
                "ok": False,
                "error": "Cannot approve Human Gate without a non-empty design_audit_report.md (pass --skip-audit only for explicit developer override).",
            }, indent=2))
            return 1

        now = datetime.now(timezone.utc).isoformat()
        meta["design_audited"] = has_audit_report
        meta["audit_skipped"] = bool(args.skip_audit and not has_audit_report)
        meta["human_gate_approved"] = True
        meta["human_gate_approved_at"] = now
        meta["human_gate_approver"] = args.approver
        meta["status"] = "approved"
        meta["phase_mode"] = "Phase 2 (Empirical Implementation)"
        if not meta.get("base_sha"):
            git_head = detect_git_head()
            if git_head:
                meta["base_sha"] = git_head
        meta["locked_hashes"] = {
            "spec_sha256": current_spec_hash,
            "plan_sha256": current_plan_hash,
            "plan_structure_sha256": current_plan_struct_hash,
        }
        save_metadata(track_dir, meta)
        print(json.dumps({"ok": True, "action": "approved", "track_dir": track_dir, "metadata": meta}, indent=2))
        return 0

    locked = meta.get("locked_hashes") if isinstance(meta.get("locked_hashes"), dict) else {}
    locked_spec = locked.get("spec_sha256", "")
    locked_plan_struct = locked.get("plan_structure_sha256", "")

    spec_drifted = bool(locked_spec and current_spec_hash != locked_spec)
    plan_drifted = bool(locked_plan_struct and current_plan_struct_hash != locked_plan_struct)

    if args.status:
        status_payload = {
            "ok": True,
            "track_dir": track_dir,
            "metadata": meta,
            "files": {
                "spec_exists": os.path.isfile(spec_path),
                "plan_exists": os.path.isfile(plan_path),
                "design_audit_report_exists": has_audit_report,
                "decisions_log_exists": os.path.isfile(os.path.join(track_dir, "decisions.tsv")),
                "verification_log_exists": os.path.isfile(os.path.join(track_dir, "verification.log")),
            },
            "drift": {
                "spec_drifted_since_lock": spec_drifted,
                "plan_structure_drifted_since_lock": plan_drifted,
            },
        }
        print(json.dumps(status_payload, indent=2))
        return 0

    reasons = []
    if not os.path.isfile(spec_path) or os.path.getsize(spec_path) == 0:
        reasons.append("Missing or empty spec.md")
    if not os.path.isfile(plan_path) or os.path.getsize(plan_path) == 0:
        reasons.append("Missing or empty plan.md")
    if not has_audit_report and not meta.get("audit_skipped"):
        reasons.append("Missing or empty zero-context design audit report (design_audit_report.md)")
    if not meta.get("human_gate_approved"):
        reasons.append("Stage 3 Human Gate has not been approved by developer (human_gate_approved is false)")
    elif not locked_spec or not locked_plan_struct:
        reasons.append("Missing locked_hashes in metadata.json; run gate_check.py --approve to lock spec.md and plan.md")
    if spec_drifted:
        reasons.append("spec.md has been modified after Human Gate approval; re-audit and re-approve before /implement")
    if plan_drifted:
        reasons.append("plan.md task/phase structure was modified after Human Gate approval; re-audit and re-approve before /implement")

    ok = len(reasons) == 0
    print(json.dumps({
        "ok": ok,
        "track_dir": track_dir,
        "phase_mode": meta.get("phase_mode", "Phase 1"),
        "human_gate_approved": bool(meta.get("human_gate_approved")),
        "design_audit_report_exists": has_audit_report,
        "spec_drifted_since_lock": spec_drifted,
        "plan_structure_drifted_since_lock": plan_drifted,
        "reasons": reasons,
    }, indent=2))
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
