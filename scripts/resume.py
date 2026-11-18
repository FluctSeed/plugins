#!/usr/bin/env python3
"""Determines the next unblocked setup step in the project initialization workflow,
with monorepo module conductor and root inheritance support."""

import argparse
import glob
import json
import os
import subprocess
import sys


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


def has_styleguides(conductor_dir: str) -> bool:
    return len(glob.glob(os.path.join(conductor_dir, "code_styleguides", "*.md"))) > 0


def determine_resumption(conductor_dir: str = "conductor") -> dict:
    repo_root = os.path.realpath(detect_repo_root())
    resolved = os.path.realpath(conductor_dir)
    root_conductor = os.path.realpath(os.path.join(repo_root, "conductor"))
    is_module = (resolved != root_conductor) and os.path.isdir(root_conductor)

    chain = [
        ("product.md", "Product Definition", False),
        ("product-guidelines.md", "Product Guidelines", True),
        ("tech-stack.md", "Technology Stack", False),
        ("code_styleguides", "Code Style Guides", True),
        ("security-policy.md", "Security Policy", True),
        ("workflow.md", "Workflow Configuration", True),
    ]

    checklist = {}
    inherited = []
    next_step = None

    for filename, step_name, inheritable in chain:
        if filename == "code_styleguides":
            present = has_styleguides(resolved)
            if not present and inheritable and is_module and has_styleguides(root_conductor):
                present = True
                inherited.append(filename)
        else:
            local_p = os.path.join(resolved, filename)
            present = os.path.isfile(local_p) and os.path.getsize(local_p) > 0
            if not present and inheritable and is_module:
                root_p = os.path.join(root_conductor, filename)
                if os.path.isfile(root_p) and os.path.getsize(root_p) > 0:
                    present = True
                    inherited.append(filename)
        checklist[filename] = present
        if not present and next_step is None:
            next_step = {"step": step_name, "file": filename}

    index_path = os.path.join(resolved, "index.md")
    has_index = os.path.isfile(index_path) and os.path.getsize(index_path) > 0
    setup_complete = has_index and (next_step is None)

    return {
        "conductor_dir": conductor_dir,
        "is_module_conductor": is_module,
        "has_index": has_index,
        "setup_complete": setup_complete,
        "checklist": checklist,
        "inherited_from_root": inherited,
        "next_step": next_step,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Determine setup resumption step")
    parser.add_argument("--conductor-dir", default="conductor", help="Path to conductor directory")
    args = parser.parse_args()
    result = determine_resumption(args.conductor_dir)
    print(json.dumps(result, indent=2))
    sys.exit(0)
