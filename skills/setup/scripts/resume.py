#!/usr/bin/env python3
"""Determines the next unblocked setup step in the project initialization workflow,
with monorepo module conductor support."""

import argparse
import json
import os
import sys


def determine_resumption(conductor_dir: str = "conductor"):
    """Checks existing setup artifacts and returns the next unblocked step."""
    files = [
        "product.md",
        "product-guidelines.md",
        "tech-stack.md",
        "code_styleguides",
        "security-policy.md",
        "workflow.md",
    ]

    checklist = {}
    for filename in files:
        path = os.path.join(conductor_dir, filename)
        checklist[filename] = os.path.exists(path)

    setup_complete = os.path.exists(os.path.join(conductor_dir, "index.md"))

    next_step = None

    chain = [
        ("product.md", "Product Definition"),
        ("product-guidelines.md", "Product Guidelines"),
        ("tech-stack.md", "Technology Stack"),
        ("code_styleguides", "Code Style Guides"),
        ("security-policy.md", "Security Policy"),
        ("workflow.md", "Workflow Configuration"),
    ]

    for filename, step_name in chain:
        if not checklist[filename]:
            next_step = {
                "step": step_name,
                "file": filename,
            }
            break

    return {
        "conductor_dir": conductor_dir,
        "setup_complete": setup_complete,
        "checklist": checklist,
        "next_step": next_step,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Determine setup resumption step")
    parser.add_argument("--conductor-dir", default="conductor", help="Path to conductor directory")
    args = parser.parse_args()
    result = determine_resumption(args.conductor_dir)
    print(json.dumps(result, indent=2))
    sys.exit(0)
