#!/usr/bin/env python3
"""Extract table of contents (headers only) from a markdown file."""

import sys
from pathlib import Path


def is_fence(line: str) -> bool:
    """Check if a line is a fenced code block delimiter (``` or ~~~)."""
    stripped = line.strip()
    return stripped.startswith("```") or stripped.startswith("~~~")


def get_toc(markdown_path: str) -> str:
    """Extract all markdown headers from a file (code-block aware).

    Args:
        markdown_path: Path to markdown file

    Returns:
        All header lines (lines starting with #)
    """
    content = Path(markdown_path).read_text()
    in_fence = False
    headers = []
    for line in content.splitlines():
        if is_fence(line):
            in_fence = not in_fence
            continue
        if not in_fence and line.strip().startswith("#"):
            headers.append(line)
    return "\n".join(headers)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <markdown_file>", file=sys.stderr)
        sys.exit(1)

    result = get_toc(sys.argv[1])
    print(result)
