#!/usr/bin/env python3
"""
File/Directory Rename and Reference Update Tool

This script renames or moves files/directories and automatically updates all 
references to them throughout the workspace.

Usage:
    python rename_and_update_refs.py <old_path> <new_path> [--dry-run]

Examples:
    # Rename a file
    python rename_and_update_refs.py docs/old.md docs/new.md
    
    # Move a file to different directory
    python rename_and_update_refs.py docs/file.md other/location/file.md --dry-run
    
    # Rename a directory (updates all file references within it)
    python rename_and_update_refs.py old_docs/ new_docs/
    
    # Move a directory to different location
    python rename_and_update_refs.py project_docs/ documentation/ --dry-run
"""

import os
import sys
import re
import argparse
from pathlib import Path
from typing import List, Tuple, Set, Dict

# File extensions to search for references
SEARCHABLE_EXTENSIONS = {
    '.md', '.txt', '.adoc'  # Documentation
}

# Directories to exclude from search
EXCLUDE_DIRS = {
    '.git', 'node_modules', '__pycache__', '.pytest_cache',
    'venv', '.venv', 'env', '.env', 'dist', 'build',
    '.next', '.cache', 'coverage', '.coverage'
}


class ReferenceUpdater:
    def __init__(self, workspace_root: Path):
        self.workspace_root = workspace_root.resolve()
        self.changes_made = []
        
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
    
    def generate_reference_patterns(self, old_path: Path) -> List[Tuple[re.Pattern, str]]:
        """Generate regex patterns to find various reference formats."""
        patterns = []
        
        # Get both absolute and relative forms
        old_name = old_path.name
        old_stem = old_path.stem
        
        # Calculate workspace-relative path
        try:
            rel_path = old_path.relative_to(self.workspace_root)
            rel_path_str = str(rel_path).replace('\\', '/')
            rel_path_posix = rel_path.as_posix()
        except ValueError:
            rel_path_str = str(old_path).replace('\\', '/')
            rel_path_posix = rel_path_str
        
        # Pattern 1: Markdown links [text](path)
        # Match both with and without .md extension
        patterns.append((
            re.compile(re.escape(rel_path_posix), re.IGNORECASE),
            'posix_path'
        ))
        
        # Pattern 2: Windows-style paths
        patterns.append((
            re.compile(re.escape(str(rel_path).replace('/', '\\')), re.IGNORECASE),
            'windows_path'
        ))
        
        # Pattern 3: Just the filename (for looser matching)
        patterns.append((
            re.compile(r'\b' + re.escape(old_name) + r'\b', re.IGNORECASE),
            'filename_only'
        ))
        
        return patterns
    
    def find_references(self, file_path: Path, old_path: Path) -> List[Tuple[int, str, str]]:
        """
        Find all references to old_path in the given file.
        Returns list of (line_number, old_line, reference_type).
        """
        references = []
        patterns = self.generate_reference_patterns(old_path)
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                for line_num, line in enumerate(f, 1):
                    for pattern, ref_type in patterns:
                        if pattern.search(line):
                            references.append((line_num, line, ref_type))
                            break  # Only report each line once
        except Exception as e:
            print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        
        return references
    
    def update_references_in_file(self, file_path: Path, old_path: Path, 
                                   new_path: Path, dry_run: bool = False) -> int:
        """
        Update all references in a file from old_path to new_path.
        Returns the number of lines updated.
        """
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
            return 0
        
        # Calculate relative paths
        try:
            old_rel = old_path.relative_to(self.workspace_root).as_posix()
            new_rel = new_path.relative_to(self.workspace_root).as_posix()
        except ValueError:
            old_rel = old_path.as_posix()
            new_rel = new_path.as_posix()
        
        old_name = old_path.name
        new_name = new_path.name
        
        updated_lines = 0
        new_lines = []
        
        for line in lines:
            new_line = line
            
            # Replace full paths (POSIX style)
            if old_rel in new_line:
                new_line = new_line.replace(old_rel, new_rel)
                updated_lines += 1
            
            # Replace full paths (Windows style)
            old_win = old_rel.replace('/', '\\')
            new_win = new_rel.replace('/', '\\')
            if old_win in new_line and new_line == line:  # Only if not already replaced
                new_line = new_line.replace(old_win, new_win)
                updated_lines += 1
            
            # Replace filename only (if not already replaced and makes sense)
            # Be careful here - only replace in certain contexts to avoid false positives
            if new_line == line and old_name != new_name:
                # Look for markdown links, file paths, etc.
                # Pattern: word boundaries around the filename
                pattern = r'\b' + re.escape(old_name) + r'\b'
                if re.search(pattern, new_line):
                    new_line = re.sub(pattern, new_name, new_line)
                    if new_line != line:
                        updated_lines += 1
            
            new_lines.append(new_line)
        
        if updated_lines > 0 and not dry_run:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)
                self.changes_made.append(f"Updated {updated_lines} reference(s) in {file_path.relative_to(self.workspace_root)}")
            except Exception as e:
                print(f"Error: Could not write to {file_path}: {e}", file=sys.stderr)
                return 0
        
        return updated_lines
    
    def get_all_files_in_directory(self, directory: Path) -> List[Path]:
        """Get all files recursively within a directory."""
        files = []
        for root, dirs, filenames in os.walk(directory):
            # Don't exclude directories here - we want all files
            for filename in filenames:
                files.append(Path(root) / filename)
        return files
    
    def rename_path(self, old_path: Path, new_path: Path, dry_run: bool = False) -> bool:
        """Rename or move a file or directory."""
        if not old_path.exists():
            print(f"Error: Path not found: {old_path}", file=sys.stderr)
            return False
        
        if new_path.exists():
            print(f"Error: Destination already exists: {new_path}", file=sys.stderr)
            return False
        
        path_type = "directory" if old_path.is_dir() else "file"
        
        if dry_run:
            print(f"[DRY RUN] Would rename {path_type}: {old_path} -> {new_path}")
            return True
        
        # Create parent directory if it doesn't exist
        new_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            old_path.rename(new_path)
            print(f"✓ Renamed {path_type}: {old_path} -> {new_path}")
            return True
        except Exception as e:
            print(f"Error: Could not rename {path_type}: {e}", file=sys.stderr)
            return False
    
    def process_directory(self, old_dir: Path, new_dir: Path, dry_run: bool = False) -> bool:
        """Process a directory rename/move and update all references."""
        print(f"=== Directory Rename and Reference Update Tool ===\n")
        print(f"Workspace:     {self.workspace_root}")
        print(f"Old directory: {old_dir}")
        print(f"New directory: {new_dir}")
        
        if dry_run:
            print("\n*** DRY RUN MODE - No changes will be made ***\n")
        
        # Step 1: Collect all files in the directory
        print("\n[1/4] Collecting files in directory...")
        files_in_dir = self.get_all_files_in_directory(old_dir)
        print(f"Found {len(files_in_dir)} file(s) in directory")
        
        # Step 2: Search for references to all files and the directory itself
        print("\n[2/4] Searching for references...")
        searchable_files = self.find_all_searchable_files()
        
        # Build a map of old_file -> new_file paths
        file_mapping: Dict[Path, Path] = {}
        
        # Map all files within the directory
        for old_file in files_in_dir:
            try:
                rel_to_old_dir = old_file.relative_to(old_dir)
                new_file = new_dir / rel_to_old_dir
                file_mapping[old_file] = new_file
            except ValueError:
                continue
        
        # Also map the directory itself
        file_mapping[old_dir] = new_dir
        
        # Find all references
        files_with_refs: Dict[Path, List[Tuple[Path, Path]]] = {}  # search_file -> [(old, new), ...]
        
        for search_file in searchable_files:
            # Skip files that are inside the directory being moved
            try:
                search_file.relative_to(old_dir)
                continue  # File is inside the moving directory, skip it
            except ValueError:
                pass  # File is outside, we should search it
            
            refs_in_file = []
            for old_path, new_path in file_mapping.items():
                refs = self.find_references(search_file, old_path)
                if refs:
                    refs_in_file.append((old_path, new_path))
            
            if refs_in_file:
                files_with_refs[search_file] = refs_in_file
        
        total_refs = sum(len(refs) for refs in files_with_refs.values())
        print(f"Found {total_refs} file(s)/reference(s) to update in {len(files_with_refs)} document(s)")
        
        # Step 3: Rename the directory
        print("\n[3/4] Renaming directory...")
        if not self.rename_path(old_dir, new_dir, dry_run):
            print("\nAborting: Directory rename failed")
            return False
        
        # Step 4: Update all references
        print("\n[4/4] Updating references...")
        total_updates = 0
        
        for search_file, mappings in files_with_refs.items():
            file_updates = 0
            for old_path, new_path in mappings:
                updates = self.update_references_in_file(search_file, old_path, new_path, dry_run)
                file_updates += updates
            
            if file_updates > 0:
                try:
                    rel_path = search_file.relative_to(self.workspace_root)
                except ValueError:
                    rel_path = search_file
                
                if dry_run:
                    print(f"[DRY RUN] Would update {file_updates} reference(s) in {rel_path}")
                else:
                    print(f"✓ Updated {file_updates} reference(s) in {rel_path}")
                total_updates += file_updates
        
        # Summary
        print("\n=== Summary ===")
        if dry_run:
            print(f"Would rename directory: {old_dir.name}/ -> {new_dir.name}/")
            print(f"Would affect {len(files_in_dir)} file(s) in directory")
            print(f"Would update {total_updates} reference(s) in {len(files_with_refs)} document(s)")
            print("\nRun without --dry-run to apply changes")
        else:
            print(f"✓ Renamed directory: {old_dir.name}/ -> {new_dir.name}/")
            print(f"✓ Moved {len(files_in_dir)} file(s)")
            print(f"✓ Updated {total_updates} reference(s) in {len(files_with_refs)} document(s)")
        
        return True
    
    def process(self, old_path: str, new_path: str, dry_run: bool = False):
        """Main processing function - handles both files and directories."""
        old_path = Path(old_path).resolve()
        new_path = Path(new_path).resolve()
        
        # Check if it's a directory or file
        if old_path.is_dir():
            return self.process_directory(old_path, new_path, dry_run)
        
        # Process as a file
        print(f"=== File Rename and Reference Update Tool ===\n")
        print(f"Workspace: {self.workspace_root}")
        print(f"Old path:  {old_path}")
        print(f"New path:  {new_path}")
        
        if dry_run:
            print("\n*** DRY RUN MODE - No changes will be made ***\n")
        
        # Step 1: Find all references before renaming
        print("\n[1/3] Searching for references...")
        searchable_files = self.find_all_searchable_files()
        print(f"Found {len(searchable_files)} files to search")
        
        files_with_refs = []
        for file_path in searchable_files:
            if file_path == old_path:
                continue  # Skip the file being renamed
            
            refs = self.find_references(file_path, old_path)
            if refs:
                files_with_refs.append((file_path, refs))
        
        print(f"Found references in {len(files_with_refs)} file(s)")
        
        # Step 2: Rename the file
        print("\n[2/3] Renaming file...")
        if not self.rename_path(old_path, new_path, dry_run):
            print("\nAborting: File rename failed")
            return False
        
        # Step 3: Update all references
        print("\n[3/3] Updating references...")
        total_updates = 0
        
        for file_path, refs in files_with_refs:
            updates = self.update_references_in_file(file_path, old_path, new_path, dry_run)
            if updates > 0:
                rel_path = file_path.relative_to(self.workspace_root)
                if dry_run:
                    print(f"[DRY RUN] Would update {updates} reference(s) in {rel_path}")
                else:
                    print(f"✓ Updated {updates} reference(s) in {rel_path}")
                total_updates += updates
        
        # Summary
        print("\n=== Summary ===")
        if dry_run:
            print(f"Would rename: {old_path.name} -> {new_path.name}")
            print(f"Would update {total_updates} reference(s) in {len(files_with_refs)} file(s)")
            print("\nRun without --dry-run to apply changes")
        else:
            print(f"✓ Renamed: {old_path.name} -> {new_path.name}")
            print(f"✓ Updated {total_updates} reference(s) in {len(files_with_refs)} file(s)")
        
        return True


def main():
    parser = argparse.ArgumentParser(
        description='Rename a file or directory and update all references to it in the workspace',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('old_path', help='Current path of the file or directory')
    parser.add_argument('new_path', help='New path for the file or directory')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be changed without making changes')
    parser.add_argument('--workspace', type=Path,
                        help='Workspace root directory (default: current directory)')
    
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
    
    updater = ReferenceUpdater(workspace_root)
    success = updater.process(args.old_path, args.new_path, args.dry_run)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
