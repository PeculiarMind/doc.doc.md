#!/usr/bin/env python3
"""
Find Broken References Tool

This script scans the workspace for broken references - links and textual
references to files that don't exist.

Usage:
    python find_broken_refs.py [--workspace PATH] [--verbose] [--format {full,simple,json}]

Examples:
    python find_broken_refs.py
    python find_broken_refs.py --verbose
    python find_broken_refs.py --workspace /path/to/project
    python find_broken_refs.py --format simple
    python find_broken_refs.py --format json | jq .
"""

import os
import sys
import re
import argparse
from pathlib import Path
from typing import List, Tuple, Set, Dict
from collections import defaultdict

# File extensions to search for references
SEARCHABLE_EXTENSIONS = {
    '.md', '.txt', '.adoc',  # Documentation
}

# Directories to exclude from search
EXCLUDE_DIRS = {
    '.git', 'node_modules', '__pycache__', '.pytest_cache',
    'venv', '.venv', 'env', '.env', 'dist', 'build',
    '.next', '.cache', 'coverage', '.coverage'
}

# URL schemes to exclude (remote addresses)
REMOTE_SCHEMES = {
    'http://', 'https://', 'ftp://', 'ftps://', 'ssh://',
    'git://', 'mailto:', 'tel:', 'data:', 'file://',
    'ws://', 'wss://', 'irc://', 'ircs://', 'sftp://'
}


class BrokenReferenceFinder:
    def __init__(self, workspace_root: Path, verbose: bool = False, output_format: str = 'full'):
        self.workspace_root = workspace_root.resolve()
        self.verbose = verbose
        self.output_format = output_format
        self.broken_refs: Dict[Path, List[Tuple[int, str, str]]] = defaultdict(list)
    
    def is_remote_url(self, path: str) -> bool:
        """Check if a path is a remote URL that should be excluded."""
        path_lower = path.lower().strip()
        
        # Check for URL schemes
        for scheme in REMOTE_SCHEMES:
            if path_lower.startswith(scheme):
                return True
        
        # Check for common URL patterns without explicit scheme
        # e.g., www.example.com, example.com
        if re.match(r'^(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}', path_lower):
            return True
        
        return False
        
    def find_all_searchable_files(self) -> List[Path]:
        """Find all files that might contain references."""
        searchable_files = []
        
        for root, dirs, files in os.walk(self.workspace_root):
            # Remove excluded directories from search
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            
            for file in files:
                file_path = Path(root) / file
                if file_path.suffix in SEARCHABLE_EXTENSIONS:
                    searchable_files.append(file_path)
        
        return searchable_files
    
    def extract_references_from_line(self, line: str, line_num: int) -> List[Tuple[str, str]]:
        """
        Extract potential file references from a line.
        Returns list of (reference_text, reference_type).
        """
        references = []
        
        # Pattern 1: Markdown links [text](path) or [text](path#anchor)
        md_links = re.findall(r'\[([^\]]+)\]\(([^)#]+?)(?:#[^)]+)?\)', line)
        for link_text, path in md_links:
            # Skip URLs and anchor-only links
            if not path.startswith('#') and not self.is_remote_url(path):
                references.append((path.strip(), 'markdown_link'))
        
        # Pattern 2: File paths with common extensions
        # Match paths like ./foo/bar/file.md, .github/agents/file.agent.md, foo/bar/file.txt, etc.
        # Supports: paths starting with ./ or ../ or .hidden/, compound extensions like .agent.md
        path_pattern = r'(?:\.\./)?(?:\.?[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+(?:\.[a-zA-Z0-9]+)+'
        
        # Look for paths in various contexts
        # In quotes: "path" or 'path'
        quoted_paths = re.findall(r'["\'](' + path_pattern + r')["\']', line)
        for match in quoted_paths:
            path = match[0] if isinstance(match, tuple) else match
            if not self.is_remote_url(path):
                references.append((path.strip(), 'quoted_path'))
        
        # In backticks: `path`
        backtick_paths = re.findall(r'`(' + path_pattern + r')`', line)
        for match in backtick_paths:
            path = match[0] if isinstance(match, tuple) else match
            if not self.is_remote_url(path):
                references.append((path.strip(), 'backtick_path'))
        
        # Plain text paths (be more conservative to avoid false positives)
        # Only match if it contains / or \ and has a file extension
        # Use lookaround instead of \b to properly handle paths starting with .
        plain_pattern = r'(?:^|(?<=[\s\[(\'"`]))((\.\.?/)?(?:\.?[a-zA-Z0-9_.-]+[/\\])+[a-zA-Z0-9_-]+(?:\.[a-zA-Z0-9]+)+)(?=[\s\])\'"`,.;:]|$)'
        plain_paths = re.findall(plain_pattern, line)
        for path in plain_paths:
            # path is a tuple from the groups, get the full match
            path_str = path[0] if isinstance(path, tuple) else path
            # Skip if it looks like a URL or domain
            if not self.is_remote_url(path_str):
                references.append((path_str.strip(), 'plain_path'))
        
        return references
    
    def resolve_path(self, ref_path: str, source_file: Path) -> Path:
        """
        Resolve a reference path relative to the source file and workspace.
        Tries multiple resolution strategies.
        """
        # Clean up the path
        ref_path = ref_path.replace('\\', '/')
        # Remove leading ./ if present (but preserve paths like .github/)
        if ref_path.startswith('./'):
            ref_path = ref_path[2:]
        
        # Strategy 1: Relative to the source file's directory
        candidate1 = (source_file.parent / ref_path).resolve()
        
        # Strategy 2: Relative to workspace root
        candidate2 = (self.workspace_root / ref_path).resolve()
        
        # Strategy 3: As-is if absolute
        candidate3 = Path(ref_path).resolve()
        
        # Return the first candidate that exists
        for candidate in [candidate1, candidate2, candidate3]:
            try:
                # Check if the path is within workspace or is the referenced path
                candidate.relative_to(self.workspace_root)
                if candidate.exists():
                    return candidate
            except ValueError:
                # Path is outside workspace, skip
                continue
        
        # None exist, return the most likely candidate (relative to source file)
        return candidate1
    
    def check_file_for_broken_refs(self, file_path: Path) -> List[Tuple[int, str, str, str]]:
        """
        Check a file for broken references.
        Returns list of (line_number, reference_text, reference_type, resolved_path).
        """
        broken = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                for line_num, line in enumerate(f, 1):
                    refs = self.extract_references_from_line(line, line_num)
                    
                    for ref_text, ref_type in refs:
                        resolved_path = self.resolve_path(ref_text, file_path)
                        
                        if not resolved_path.exists():
                            broken.append((line_num, ref_text, ref_type, str(resolved_path)))
        
        except Exception as e:
            if self.verbose:
                print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        
        return broken
    
    def scan_workspace(self):
        """Scan the entire workspace for broken references."""
        if self.output_format == 'full':
            print(f"=== Broken Reference Finder ===\n")
            print(f"Workspace: {self.workspace_root}")
            print(f"Scanning for broken references...\n")
        
        searchable_files = self.find_all_searchable_files()
        
        if self.output_format == 'full':
            print(f"Searching {len(searchable_files)} file(s)...")
        
        total_broken = 0
        files_with_issues = 0
        
        for file_path in searchable_files:
            broken = self.check_file_for_broken_refs(file_path)
            
            if broken:
                self.broken_refs[file_path] = broken
                total_broken += len(broken)
                files_with_issues += 1
        
        if self.output_format == 'full':
            print(f"Scan complete: Found {total_broken} broken reference(s) in {files_with_issues} file(s)\n")
        
        return total_broken
    
    def print_results_simple(self):
        """Print results in simple format: <file> <tangledRef>"""
        for file_path in sorted(self.broken_refs.keys()):
            try:
                rel_path = file_path.relative_to(self.workspace_root)
            except ValueError:
                rel_path = file_path
            
            broken_refs = self.broken_refs[file_path]
            for line_num, ref_text, ref_type, resolved_path in broken_refs:
                print(f"{rel_path} {ref_text}")
    
    def print_results_json(self):
        """Print results in JSON format: {"file":"path", "tangledRef":"ref"}"""
        import json
        for file_path in sorted(self.broken_refs.keys()):
            try:
                rel_path = str(file_path.relative_to(self.workspace_root))
            except ValueError:
                rel_path = str(file_path)
            
            broken_refs = self.broken_refs[file_path]
            for line_num, ref_text, ref_type, resolved_path in broken_refs:
                result = {
                    "file": rel_path,
                    "tangledRef": ref_text,
                    "line": line_num,
                    "type": ref_type
                }
                print(json.dumps(result))
    
    def print_results(self):
        """Print the results based on selected output format."""
        if self.output_format == 'simple':
            self.print_results_simple()
            return
        
        if self.output_format == 'json':
            self.print_results_json()
            return
        
        # Full format
        if not self.broken_refs:
            print("✓ No broken references found!")
            return
        
        print("=== Broken References ===\n")
        
        # Sort by file path for consistent output
        for file_path in sorted(self.broken_refs.keys()):
            try:
                rel_path = file_path.relative_to(self.workspace_root)
            except ValueError:
                rel_path = file_path
            
            print(f"\n{rel_path}")
            print("─" * len(str(rel_path)))
            
            broken_refs = self.broken_refs[file_path]
            for line_num, ref_text, ref_type, resolved_path in broken_refs:
                print(f"  Line {line_num:4d} [{ref_type:14s}]: {ref_text}")
                if self.verbose:
                    print(f"              → Resolved to: {resolved_path}")
                    print(f"              → File does not exist")
    
    def print_summary(self):
        """Print a summary of broken references."""
        if not self.broken_refs or self.output_format != 'full':
            return
        
        total_broken = sum(len(refs) for refs in self.broken_refs.values())
        
        print(f"\n{'═' * 60}")
        print(f"Summary: {total_broken} broken reference(s) in {len(self.broken_refs)} file(s)")
        print(f"{'═' * 60}")
        
        # Group by reference type
        type_counts = defaultdict(int)
        for refs in self.broken_refs.values():
            for _, _, ref_type, _ in refs:
                type_counts[ref_type] += 1
        
        if type_counts:
            print("\nBy type:")
            for ref_type, count in sorted(type_counts.items()):
                print(f"  {ref_type:20s}: {count}")


def main():
    parser = argparse.ArgumentParser(
        description='Find broken references in the workspace',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--workspace', type=Path,
                        help='Workspace root directory (default: current directory)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show verbose output including resolved paths')
    parser.add_argument('--format', '-f', 
                        choices=['full', 'simple', 'json'],
                        default='full',
                        help='Output format: full (default, human-readable), simple (one line per finding), json (JSON lines)')
    
    args = parser.parse_args()
    
    # Determine workspace root
    if args.workspace:
        workspace_root = args.workspace
    else:
        # Try to find workspace root by looking for common markers
        current = Path.cwd()
        workspace_root = current
        
        # Look for .git or common root files
        while current != current.parent:
            if (current / '.git').exists() or (current / 'AGENTS.md').exists():
                workspace_root = current
                break
            current = current.parent
    
    finder = BrokenReferenceFinder(workspace_root, verbose=args.verbose, output_format=args.format)
    total_broken = finder.scan_workspace()
    finder.print_results()
    finder.print_summary()
    
    # Exit with non-zero status if broken references found
    sys.exit(1 if total_broken > 0 else 0)


if __name__ == '__main__':
    main()
