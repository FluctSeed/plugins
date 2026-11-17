#!/usr/bin/env python3
"""Assembles the zero-context reading list from conductor/ and directory README.md architecture contracts."""

import argparse
import glob
import json
import os
import sys


def collect_audit_context(root_dir: str = ".") -> dict:
    conductor_dir = os.path.join(root_dir, "conductor")
    core_docs = []
    for name in [
        "index.md",
        "product.md",
        "product-guidelines.md",
        "tech-stack.md",
        "security-policy.md",
        "workflow.md",
    ]:
        p = os.path.join(conductor_dir, name)
        if os.path.exists(p):
            core_docs.append(os.path.relpath(p, root_dir))

    styleguides = sorted(
        os.path.relpath(p, root_dir)
        for p in glob.glob(os.path.join(conductor_dir, "code_styleguides", "*.md"))
    )

    contracts = []
    ignore_dirs = {".git", "node_modules", "dist", "build", "venv", ".venv", "conductor", ".claude", ".codex", ".agent", ".agents", ".grok"}
    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if d not in ignore_dirs and not d.startswith(".")]
        if "README.md" in filenames:
            rel = os.path.relpath(os.path.join(dirpath, "README.md"), root_dir)
            contracts.append(rel)

    reading_list = core_docs + styleguides + sorted(contracts)
    return {
        "project_context": core_docs,
        "styleguides": styleguides,
        "architecture_contracts": sorted(contracts),
        "audit_context": reading_list,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assemble zero-context audit reading list")
    parser.add_argument("--root", default=".", help="Project root directory")
    args = parser.parse_args()
    print(json.dumps(collect_audit_context(args.root), indent=2, ensure_ascii=False))
    sys.exit(0)
