#!/usr/bin/env python3
"""Standalone Mustache template renderer for doc.doc.md.

Usage: mustache_render.py <template_file> <json_string>

Renders the template using the full Mustache specification via the chevron
library.  Derives ``fileName`` from ``filePath`` automatically so templates
can use ``{{fileName}}`` without the caller having to provide it.

Exit codes:
  0  Success – rendered content written to stdout.
  1  Error   – diagnostic written to stderr.
"""

import json
import os
import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: mustache_render.py <template_file> <json_string>", file=sys.stderr)
        sys.exit(1)

    template_file = sys.argv[1]
    json_string = sys.argv[2]

    # --- Validate inputs ---
    if not os.path.isfile(template_file):
        print(f"Error: Template file not found: {template_file}", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(json_string)
    except (json.JSONDecodeError, ValueError) as exc:
        print(f"Error: Invalid JSON: {exc}", file=sys.stderr)
        sys.exit(1)

    # --- Derive fileName from filePath ---
    file_path = data.get("filePath", "")
    if file_path:
        data.setdefault("fileName", os.path.basename(file_path))

    # --- Load chevron ---
    try:
        import chevron
    except ImportError:
        print("Error: chevron library not installed (pip install chevron)", file=sys.stderr)
        sys.exit(1)

    # --- Read template ---
    try:
        with open(template_file, "r", encoding="utf-8") as fh:
            template_content = fh.read()
    except OSError as exc:
        print(f"Error: Cannot read template: {exc}", file=sys.stderr)
        sys.exit(1)

    # --- Render ---
    rendered = chevron.render(template_content, data)
    sys.stdout.write(rendered)


if __name__ == "__main__":
    main()
