#!/usr/bin/env python3
"""Enforces the Stage 3 Human Gate & Zero-Context Design Audit lock between /new-track and /implement.

Usage:
  python3 scripts/gate_check.py --status <track_id_or_path>
  python3 scripts/gate_check.py --approve <track_id_or_path> [--approver <name>]
  python3 scripts/gate_check.py --verify <track_id_or_path>
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import sys


def resolve_track_dir(target: str) -> str:
    if os.path.isdir(target):
        return target
    candidate = os.path.join("conductor", "tracks", target)
    if os.path.isdir(candidate):
        return candidate
    raise FileNotFoundError(f"Track directory not found for '{target}' (checked '{candidate}')")


def sha256_file(path: str) -> str:
    if not os.path.exists(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def load_metadata(track_dir: str) -> dict:
    meta_path = os.path.join(track_dir, "metadata.json")
    if os.path.exists(meta_path):
        with open(meta_path, "r", encoding="utf-8") as f:
            return json.load(f)
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
    args = parser.parse_args()

    target = args.status or args.approve or args.verify
    try:
        track_dir = resolve_track_dir(target)
    except FileNotFoundError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2))
        return 1

    spec_path = os.path.join(track_dir, "spec.md")
    plan_path = os.path.join(track_dir, "plan.md")
    audit_path = os.path.join(track_dir, "design_audit_report.md")

    meta = load_metadata(track_dir)
    current_spec_hash = sha256_file(spec_path)
    current_plan_hash = sha256_file(plan_path)
    has_audit_report = os.path.exists(audit_path)

    if args.approve:
        if not current_spec_hash or not current_plan_hash:
            print(json.dumps({
                "ok": False,
                "error": "Cannot approve Human Gate. Both spec.md and plan.md must exist in the track directory."
            }, indent=2))
            return 1
        now = datetime.now(timezone.utc).isoformat()
        meta["design_audited"] = has_audit_report
        meta["human_gate_approved"] = True
        meta["human_gate_approved_at"] = now
        meta["human_gate_approver"] = args.approver
        meta["status"] = "approved"
        meta["phase_mode"] = "Phase 2 (Empirical Implementation)"
        meta["locked_hashes"] = {
            "spec_sha256": current_spec_hash,
            "plan_sha256": current_plan_hash,
        }
        save_metadata(track_dir, meta)
        print(json.dumps({
            "ok": True,
            "action": "approved",
            "track_dir": track_dir,
            "metadata": meta,
        }, indent=2))
        return 0

    if args.verify:
        approved = bool(meta.get("human_gate_approved"))
        locked_spec = meta.get("locked_hashes", {}).get("spec_sha256", "")
        spec_drifted = bool(locked_spec and current_spec_hash and locked_spec != current_spec_hash)

        reasons = []
        if not current_spec_hash:
            reasons.append("Missing spec.md")
        if not current_plan_hash:
            reasons.append("Missing plan.md")
        if not has_audit_report and not meta.get("design_audited"):
            reasons.append("Missing zero-context design audit report (design_audit_report.md)")
        if not approved:
            reasons.append("Stage 3 Human Gate has not been approved by developer (human_gate_approved is false)")
        if spec_drifted:
            reasons.append("spec.md was modified after Human Gate lock. Re-approval is required.")

        ok = len(reasons) == 0
        print(json.dumps({
            "ok": ok,
            "track_dir": track_dir,
            "phase_mode": meta.get("phase_mode", "Phase 1 (Spec & Zero-Context Audit)"),
            "human_gate_approved": approved,
            "design_audit_report_exists": has_audit_report,
            "spec_drifted_since_lock": spec_drifted,
            "reasons": reasons,
        }, indent=2))
        return 0 if ok else 2

    print(json.dumps({
        "ok": True,
        "track_dir": track_dir,
        "metadata": meta,
        "files": {
            "spec_exists": bool(current_spec_hash),
            "plan_exists": bool(current_plan_hash),
            "design_audit_report_exists": has_audit_report,
            "decisions_log_exists": os.path.exists(os.path.join(track_dir, "decisions.tsv")),
            "verification_log_exists": os.path.exists(os.path.join(track_dir, "verification.log")),
        },
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
