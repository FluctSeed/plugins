#!/usr/bin/env python3
"""Assembles the zero-context reading list from conductor/ and directory README.md architecture contracts,
with monorepo root detection, CWD module resolution, per-file styleguide inheritance, and bounded README scanning."""

import argparse
import glob
import json
import os
import subprocess
import sys

IGNORE_DIRS = {
    ".git", "node_modules", "dist", "build", "venv", ".venv",
    "vendor", "third_party", "target", "out", "coverage", "__pycache__", "pods",
    "conductor", "tracks", "archive", ".claude", ".codex", ".agent", ".agents", ".gemini", ".grok",
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


def find_monorepo_conductors(root_dir: str = None) -> list:
    base = os.path.abspath(root_dir) if root_dir else detect_repo_root()
    conductors = []
    walk_ignore = IGNORE_DIRS - {"conductor"}
    for dirpath, dirnames, _ in os.walk(base):
        dirnames[:] = [
            d for d in dirnames
            if d not in walk_ignore and not d.startswith(".") and not d.startswith("bazel-")
        ]
        if os.path.basename(dirpath) == "conductor":
            conductors.append(os.path.relpath(dirpath, base))
            dirnames[:] = []
    return sorted(conductors)


def find_readme_contracts(scan_root: str, repo_root: str, max_contracts: int = 50) -> list:
    contracts = []
    root_readme = os.path.join(repo_root, "README.md")
    if os.path.isfile(root_readme):
        contracts.append(os.path.relpath(root_readme, repo_root))

    # Prefer git ls-files to honor .gitignore and skip untracked vendor/build trees
    used_git = False
    try:
        p = subprocess.run(
            ["git", "-C", scan_root, "ls-files", "--cached", "--others", "--exclude-standard"],
            capture_output=True, text=True, check=True,
        )
        used_git = True
        for rel_line in sorted(p.stdout.splitlines()):
            if os.path.basename(rel_line) != "README.md":
                continue
            parts = set(rel_line.split("/"))
            if parts & IGNORE_DIRS or any(seg.startswith("bazel-") for seg in parts):
                continue
            abs_p = os.path.join(scan_root, rel_line)
            if os.path.isfile(abs_p):
                repo_rel = os.path.relpath(abs_p, repo_root)
                if repo_rel not in contracts:
                    contracts.append(repo_rel)
    except Exception:
        used_git = False

    if not used_git:
        for dirpath, dirnames, filenames in os.walk(scan_root):
            dirnames[:] = [
                d for d in dirnames
                if d not in IGNORE_DIRS and not d.startswith(".") and not d.startswith("bazel-")
            ]
            if "README.md" in filenames:
                abs_p = os.path.join(dirpath, "README.md")
                repo_rel = os.path.relpath(abs_p, repo_root)
                if repo_rel not in contracts:
                    contracts.append(repo_rel)

    return contracts[:max_contracts], len(contracts) > max_contracts


def collect_audit_context(root_dir: str = None, conductor_dir: str = None, max_contracts: int = 50) -> dict:
    repo_root = os.path.realpath(root_dir) if root_dir else os.path.realpath(detect_repo_root())
    cwd = os.path.realpath(os.getcwd())

    if conductor_dir:
        resolved_conductor = os.path.realpath(conductor_dir)
    else:
        cwd_conductor = os.path.join(cwd, "conductor")
        root_cand = os.path.join(repo_root, "conductor")
        if os.path.isdir(cwd_conductor):
            resolved_conductor = os.path.realpath(cwd_conductor)
        elif os.path.isdir(root_cand):
            resolved_conductor = os.path.realpath(root_cand)
        else:
            found = find_monorepo_conductors(repo_root)
            resolved_conductor = os.path.realpath(os.path.join(repo_root, found[0])) if found else os.path.realpath(root_cand)

    root_conductor = os.path.realpath(os.path.join(repo_root, "conductor"))
    is_module_conductor = (resolved_conductor != root_conductor) and os.path.isdir(root_conductor)

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
        p = os.path.join(resolved_conductor, name)
        if os.path.isfile(p):
            core_docs.append(os.path.relpath(p, repo_root))
        elif is_module_conductor:
            root_p = os.path.join(root_conductor, name)
            if os.path.isfile(root_p):
                inherited_docs.append(os.path.relpath(root_p, repo_root))

    # Per-filename styleguide merge: module files win, non-overridden root styleguides are inherited
    styleguide_map = {}
    if is_module_conductor:
        for p in sorted(glob.glob(os.path.join(root_conductor, "code_styleguides", "*.md"))):
            styleguide_map[os.path.basename(p)] = os.path.relpath(p, repo_root)
    for p in sorted(glob.glob(os.path.join(resolved_conductor, "code_styleguides", "*.md"))):
        styleguide_map[os.path.basename(p)] = os.path.relpath(p, repo_root)
    styleguides = [styleguide_map[k] for k in sorted(styleguide_map.keys())]

    module_root = os.path.dirname(resolved_conductor)
    scan_root = module_root if os.path.isdir(module_root) else repo_root
    contracts, truncated = find_readme_contracts(scan_root, repo_root, max_contracts=max_contracts)

    reading_list = core_docs + inherited_docs + styleguides + contracts
    return {
        "repo_root": repo_root,
        "conductor_dir": os.path.relpath(resolved_conductor, repo_root),
        "is_module_conductor": is_module_conductor,
        "project_context": core_docs,
        "inherited_context": inherited_docs,
        "styleguides": styleguides,
        "architecture_contracts": contracts,
        "contracts_truncated": truncated,
        "audit_context": reading_list,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assemble zero-context audit reading list with monorepo module awareness")
    parser.add_argument("--root", default=None, help="Explicit project or monorepo root directory (defaults to git top-level)")
    parser.add_argument("--conductor-dir", default=None, help="Explicit module conductor directory (e.g. packages/auth/conductor)")
    parser.add_argument("--max-contracts", type=int, default=50, help="Maximum README.md contracts to include (default: 50)")
    parser.add_argument("--list-conductors", action="store_true", help="List all discovered conductor directories in monorepo")
    args = parser.parse_args()

    if args.list_conductors:
        print(json.dumps(find_monorepo_conductors(args.root), indent=2))
        sys.exit(0)

    print(json.dumps(collect_audit_context(args.root, args.conductor_dir, args.max_contracts), indent=2, ensure_ascii=False))
    sys.exit(0)
