#!/usr/bin/env python3
"""
Filter engine for doc.doc.md
Reads file paths from stdin (one per line) and outputs filtered paths to stdout.
Supports include/exclude criteria with AND/OR logic per ARC_0001.

Include logic: OR within parameter (comma-separated), AND between parameters.
Exclude logic: OR within parameter (comma-separated), AND between parameters.

Filter types auto-detected:
  - File extensions: start with '.' (e.g., '.pdf', '.txt')
  - MIME types: contain '/' (e.g., 'text/plain', 'image/*')
  - Glob patterns: everything else (e.g., '**/2024/**')
"""

import argparse
import fnmatch
import os
import shutil
import subprocess
import sys


def _get_mime_type(file_path: str) -> str:
    """Return the MIME type of file_path using the `file` command.

    Raises SystemExit with a non-zero code if `file` is not available.
    Returns an empty string if the command fails for a specific file.
    """
    if shutil.which('file') is None:
        print(
            "error: 'file' command not found — required for MIME type filtering",
            file=sys.stderr,
        )
        sys.exit(1)
    result = subprocess.run(
        ['file', '--mime-type', '-b', file_path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ''
    return result.stdout.strip()


def matches_criterion(file_path: str, criterion: str) -> bool:
    """Check if a file path matches a single filter criterion."""
    criterion = criterion.strip()
    if not criterion:
        return False

    # Extension match: criterion starts with '.'
    if criterion.startswith('.'):
        return file_path.endswith(criterion)

    # MIME type match: criterion contains '/' but not '**'
    # (consistent with ARC_0001 criterion routing: MIME criteria have '/' but not '**')
    if '/' in criterion and '**' not in criterion:
        if os.path.isfile(file_path):
            # Actual file path: resolve MIME type via `file` command and compare
            mime_type = _get_mime_type(file_path)
            return fnmatch.fnmatch(mime_type, criterion)
        # MIME type string passed directly (e.g. from doc.doc.sh MIME gate):
        # match the string itself against the criterion pattern
        return fnmatch.fnmatch(file_path, criterion)

    # Glob pattern match
    return fnmatch.fnmatch(file_path, criterion)


def should_process_file(
    file_path: str,
    include_params: list[str],
    exclude_params: list[str],
) -> bool:
    """
    Determine if a file should be processed based on include/exclude filters.

    Args:
        file_path: Path to the file.
        include_params: List of include parameter strings (comma-separated criteria).
        exclude_params: List of exclude parameter strings (comma-separated criteria).

    Returns:
        True if file should be processed.
    """
    # Include logic: AND between parameters, OR within each parameter
    if not include_params:
        include_match = True
    else:
        include_match = all(
            any(
                matches_criterion(file_path, criterion)
                for criterion in param.split(',')
            )
            for param in include_params
        )

    # Exclude logic: AND between parameters, OR within each parameter
    if not exclude_params:
        exclude_match = False
    else:
        exclude_match = all(
            any(
                matches_criterion(file_path, criterion)
                for criterion in param.split(',')
            )
            for param in exclude_params
        )

    return include_match and not exclude_match


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Filter file paths based on include/exclude criteria.'
    )
    parser.add_argument(
        '--include', action='append', default=[],
        help='Include criteria (comma-separated, repeatable). '
             'OR within parameter, AND between parameters.'
    )
    parser.add_argument(
        '--exclude', action='append', default=[],
        help='Exclude criteria (comma-separated, repeatable). '
             'OR within parameter, AND between parameters.'
    )
    args = parser.parse_args()

    for line in sys.stdin:
        file_path = line.rstrip('\n')
        if not file_path:
            continue
        if should_process_file(file_path, args.include, args.exclude):
            print(file_path)

    return 0


if __name__ == '__main__':
    sys.exit(main())
