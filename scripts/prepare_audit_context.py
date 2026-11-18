#!/usr/bin/env python3
"""Assembles the zero-context reading list from conductor/ and directory README.md architecture contracts,
with full support for monorepos, module-level conductor directories, and root context inheritance."""

import argparse
import glob
import json
import os
import sys


def find_monorepo_conductors(root_dir: str = ".") -> list:
    """Finds all conductor/ directories across the repository."""
    conductors = []
    ignore_dirs = {".git", "node_modules", "dist", "build", "venv", ".venv", ".claude", ".codex", ".agent", ".agents", ".grok"}
    for dirpath, dirnames, _ in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if d not in ignore_dirs and not d.startswith(".")]
        if os.path.basename(dirpath) == "conductor":
            conductors.append(os.path.normpath(dirpath))
    return sorted(conductors)


def collect_audit_context(root_dir: str = ".", conductor_dir: str = None) -> dict:
    if not conductor_dir:
        # Check if root ./conductor exists
        candidate = os.path.join(root_dir, "conductor")
        if os.path.isdir(candidate):
            conductor_dir = candidate
        else:
            # Look for any discovered conductor
            found = find_monorepo_conductors(root_dir)
            conductor_dir = found[0] if found else candidate

    conductor_dir = os.path.normpath(conductor_dir)
    root_conductor = os.path.normpath(os.path.join(root_dir, "conductor"))
    is_module_conductor = (conductor_dir != root_conductor) and os.path.isdir(root_conductor)

    doc_names = [
        "index.md",
        "product.md",
        "product-guidelines.md",
        "tech-stack.md",
        "security-policy.md",
        "workflow.md",
    ]

    core_docs = []
    inherited_docs = []

    for name in doc_names:
        p = os.path.join(conductor_dir, name)
        if os.path.exists(p):
            core_docs.append(os.path.relpath(p, root_dir))
        elif is_module_conductor:
            root_p = os.path.join(root_conductor, name)
            if os.path.exists(root_p):
                inherited_docs.append(os.path.relpath(root_p, root_dir))

    # Style guides: local module overrides first; if empty, inherit from root conductor
    styleguides = sorted(
        os.path.relpath(p, root_dir)
        for p in glob.glob(os.path.join(conductor_dir, "code_styleguides", "*.md"))
    )
    if not styleguides and is_module_conductor:
        styleguides = sorted(
            os.path.relpath(p, root_dir)
            for p in glob.glob(os.path.join(root_conductor, "code_styleguides", "*.md"))
        )

    # Architecture contracts: scope to module tree if module conductor, plus root README.md
    module_root = os.path.dirname(conductor_dir) if conductor_dir != "conductor" else root_dir
    contracts = []
    ignore_dirs = {".git", "node_modules", "dist", "build", "venv", ".venv", "conductor", ".claude", ".codex", ".agent", ".agents", ".grok"}

    # Include root README.md if present
    root_readme = os.path.join(root_dir, "README.md")
    if os.path.exists(root_readme):
        contracts.append(os.path.relpath(root_readme, root_dir))

    # Search module tree (or entire root)
    scan_root = module_root if module_root and module_root != "." else root_dir
    for dirpath, dirnames, filenames in os.walk(scan_root):
        dirnames[:] = [d for d in dirnames if d not in ignore_dirs and not d.startswith(".")]
        if "README.md" in filenames:
            rel = os.path.relpath(os.path.join(dirpath, "README.md"), root_dir)
            if rel not in contracts:
                contracts.append(rel)

    reading_list = core_docs + inherited_docs + styleguides + sorted(contracts)
    return {
        "conductor_dir": conductor_dir,
        "is_module_conductor": is_module_conductor,
        "project_context": core_docs,
        "inherited_context": inherited_docs,
        "styleguides": styleguides,
        "architecture_contracts": sorted(contracts),
        "audit_context": reading_list,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assemble zero-context audit reading list with monorepo module awareness")
    parser.add_argument("--root", default=".", help="Project or monorepo root directory")
    parser.add_argument("--conductor-dir", default=None, help="Explicit module conductor directory (e.g. packages/auth/conductor)")
    parser.add_argument("--list-conductors", action="store_true", help="List all discovered conductor directories in monorepo")
    args = parser.parse_args()

    if args.list_conductors:
        print(json.dumps(find_monorepo_conductors(args.root), indent=2))
        sys.exit(0)

    print(json.dumps(collect_audit_context(args.root, args.conductor_dir), indent=2, ensure_ascii=False))
    sys.exit(0)
