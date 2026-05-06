#!/usr/bin/env python3
"""Extract multiple sections from a markdown file by heading names."""

import re
import sys
from pathlib import Path


def is_fence(line: str) -> bool:
    """Check if a line is a fenced code block delimiter (``` or ~~~)."""
    stripped = line.strip()
    return stripped.startswith("```") or stripped.startswith("~~~")


def extract_section(lines: list[str], section_name: str) -> str | None:
    """Extract content under a specific markdown heading (code-block aware).

    Args:
        lines: File content as list of lines
        section_name: Heading text (without # symbols)

    Returns:
        Section content including the heading, or None if not found
    """
    pattern = re.compile(rf"^(#+)\s+{re.escape(section_name)}\s*$")

    start_idx = None
    start_level = None
    in_fence = False

    for i, line in enumerate(lines):
        if is_fence(line):
            in_fence = not in_fence
            continue

        if in_fence:
            continue

        match = pattern.match(line)
        if match and start_idx is None:
            start_idx = i
            start_level = len(match.group(1))
            continue

        if start_idx is not None:
            header_match = re.match(r"^(#+)\s", line)
            if header_match and len(header_match.group(1)) <= start_level:
                return "".join(lines[start_idx:i])

    return "".join(lines[start_idx:]) if start_idx is not None else None


def extract_sections(
    markdown_path: str, section_names: list[str]
) -> dict[str, str | None]:
    """Extract multiple sections in one call.

    Args:
        markdown_path: Path to markdown file
        section_names: List of heading texts to extract

    Returns:
        Dict mapping section names to their content (None if not found)
    """
    content = Path(markdown_path).read_text()
    lines = content.splitlines(keepends=True)

    results = {}
    for name in section_names:
        results[name] = extract_section(lines, name)
    return results


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            f"Usage: {sys.argv[0]} <markdown_file> <section1> [section2] ...",
            file=sys.stderr,
        )
        sys.exit(1)

    markdown_path = sys.argv[1]
    section_names = sys.argv[2:]

    results = extract_sections(markdown_path, section_names)

    for name, content in results.items():
        print(f"--- {name} ---")
        if content:
            print(content)
        else:
            print("(Section not found)\n")
