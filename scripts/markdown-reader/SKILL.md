---
name: markdown-reader
description: Token-efficient markdown file reading. Use when working with large markdown files to avoid loading full content into context. Read table of contents first to understand structure, then extract specific sections as needed.
---

# Markdown Reader

Read markdown files efficiently without loading full content into context.

## Quick Commands

### 1. Read Table of Contents

Get file structure (headers only) first:

```bash
python get_toc.py <markdown_file>
```

[get_toc.py](get_toc.py)

### 2. Extract Specific Sections

Load only needed sections by heading name:

```bash
python extract_sections.py <markdown_file> <section1> [section2] ...
```

[extract_sections.py](extract_sections.py)

## Example Workflow

```bash
# 1. Check structure
python get_toc.py docs/plan.md

# 2. Read only "Implementation" and "Testing" sections
python extract_sections.py docs/plan.md "Implementation" "Testing"
```

## Features

- **Code-block aware**: Ignores headers inside fenced code blocks (` ``` ` or `~~~`)
- **Exact matching**: Section names must match heading text exactly (without `#` symbols)
- **Hierarchical extraction**: Extracts content until next same-level or higher-level heading

