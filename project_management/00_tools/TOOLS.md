# Project Tools

This directory contains utility scripts and tools to support project management and maintenance tasks.

## Available Tools

### rename_and_update_refs.py

A Python script that intelligently renames or moves files and directories while automatically updating all references throughout the workspace.

### find_broken_refs.py

A Python script that scans the workspace for broken references - links and textual references to files that don't exist.

---

## rename_and_update_refs.py

#### Purpose

When refactoring project structure or reorganizing documentation, manually updating all references to moved files is error-prone and time-consuming. This tool automates the entire process:

1. Renames/moves the file or directory
2. Searches all workspace files for references
3. Updates all found references to the new location

#### Usage

```bash
# Basic syntax
python3 project_management/00_tools/rename_and_update_refs.py <old_path> <new_path> [--dry-run]

# Rename a single file
python3 project_management/00_tools/rename_and_update_refs.py \
  project_documentation/old_file.md \
  project_documentation/new_file.md

# Move a file to different directory
python3 project_management/00_tools/rename_and_update_refs.py \
  README.md \
  project_documentation/03_user_guide/README.md

# Rename a directory (updates all nested file references)
python3 project_management/00_tools/rename_and_update_refs.py \
  old_docs/ \
  new_docs/

# Move a directory tree
python3 project_management/00_tools/rename_and_update_refs.py \
  temp_folder/ \
  project_management/02_project_vision/temp_folder/

# Always test with --dry-run first!
python3 project_management/00_tools/rename_and_update_refs.py \
  old_path \
  new_path \
  --dry-run
```

#### Options

| Option | Description |
|--------|-------------|
| `old_path` | Current path of the file or directory (required) |
| `new_path` | New path for the file or directory (required) |
| `--dry-run` | Preview changes without applying them (recommended for first run) |
| `--workspace PATH` | Specify workspace root directory (default: auto-detected) |

#### How It Works

**Step 1: Reference Discovery**
- Scans all searchable files in the workspace (`.md`, `.txt`, `.py`, `.json`, `.yaml`, etc.)
- Excludes common directories like `.git`, `node_modules`, `__pycache__`, build outputs
- Generates multiple search patterns for each target:
  - Full POSIX paths: `foo/bar/file.md`
  - Windows paths: `foo\bar\file.md`
  - Filename only: `file.md` (with word boundaries)

**Step 2: Pattern Matching**
- Finds references regardless of syntax:
  - Plain text: `./foo/bar/file.md`
  - Quoted: `'./foo/bar/file.md'` or `"./foo/bar/file.md"`
  - Backticks: `` `./foo/bar/file.md` ``
  - Markdown links: `[link](foo/bar/file.md)`
  - Any combination of the above

**Step 3: File/Directory Rename**
- Creates parent directories if needed
- Validates that destination doesn't already exist
- Performs atomic rename/move operation

**Step 4: Reference Updates**
- Replaces all found references with new paths
- Preserves surrounding syntax (quotes, backticks, etc.)
- Updates files in-place with UTF-8 encoding

**Step 5: Summary Report**
- Lists all modified files
- Counts total updates made
- Provides clear success/failure feedback

#### Directory Support

When renaming/moving directories, the tool:
- Recursively collects all files within the directory
- Builds a mapping of old paths → new paths for every file
- Updates references to both the directory itself and all nested files
- Example: Moving `docs/` to `documentation/` will update:
  - `docs/guide.md` → `documentation/guide.md`
  - `docs/api/reference.md` → `documentation/api/reference.md`
  - References to any file within the moved tree

#### File Type Support

The script searches these file types by default:

**Documentation**: `.md`, `.txt`, `.adoc`  

#### Best Practices

1. **Always use `--dry-run` first** to preview changes before applying them
2. **Commit your work** before running the tool so you can revert if needed
3. **Review the summary** to ensure expected files were updated
4. **Run from workspace root** for best results (auto-detection works from subdirectories too)
5. **Use relative paths** rather than absolute paths when possible
6. **Check excluded directories** if you expect files to be found but they're not being detected

#### Examples

**Example 1: Reorganizing documentation**
```bash
# Preview the move
python3 project_management/00_tools/rename_and_update_refs.py \
  project_documentation/guide.md \
  project_documentation/03_user_guide/guide.md \
  --dry-run

# Apply the move
python3 project_management/00_tools/rename_and_update_refs.py \
  project_documentation/guide.md \
  project_documentation/03_user_guide/guide.md
```

**Example 2: Renaming a requirements file**
```bash
python3 project_management/00_tools/rename_and_update_refs.py \
  project_management/02_project_vision/02_requirements/03_accepted/REQ-001.md \
  project_management/02_project_vision/02_requirements/03_accepted/REQ-AUTH-001.md
```

**Example 3: Moving an entire agent folder**
```bash
python3 project_management/00_tools/rename_and_update_refs.py \
  .github/old_agents/ \
  .github/agents/ \
  --dry-run
```

#### Troubleshooting

**Problem**: "Path not found" error  
**Solution**: Check that the old path exists and is spelled correctly. Paths are case-sensitive on Linux.

**Problem**: "Destination already exists" error  
**Solution**: Remove or rename the conflicting file/directory at the destination first.

**Problem**: Expected references weren't updated  
**Solution**: 
- Verify the file containing the reference has a searchable extension (see File Type Support)
- Check if the file is in an excluded directory (`.git`, `node_modules`, etc.)
- The reference might use an absolute path or different format than expected

**Problem**: Too many false positives in filename-only matching  
**Solution**: The script uses word boundaries to reduce false positives. If issues persist, references should use full paths rather than just filenames.

#### Limitations

- **Encoding**: Files must be UTF-8 compatible (uses `errors='ignore'` for robustness)
- **Line-based**: Assumes references don't span multiple lines
- **String replacement**: Uses literal string replacement, not semantic analysis
- **Symlinks**: Follows symlinks during search but doesn't update symlink targets
- **Git history**: Doesn't rewrite Git history (use `git filter-repo` for that)

#### Technical Details

**Language**: Python 3.7+  
**Dependencies**: Standard library only (no external packages required)  
**Entry point**: `rename_and_update_refs.py`  
**Key modules**: `pathlib`, `re`, `argparse`, `os`, `sys`

---

## find_broken_refs.py

A Python script that detects broken references throughout the workspace - identifying links and textual references to files that don't exist.

#### Purpose

Maintaining reference integrity across documentation and code is challenging in large projects. This tool scans the entire workspace to find references pointing to non-existent files, helping to:

1. Identify broken links in documentation
2. Detect outdated file references after restructuring
3. Validate documentation before releases
4. Find references in code comments pointing to missing files

#### Usage

```bash
# Basic scan
python3 project_management/00_tools/find_broken_refs.py

# Show verbose output with resolved paths
python3 project_management/00_tools/find_broken_refs.py --verbose

# Scan a specific workspace
python3 project_management/00_tools/find_broken_refs.py --workspace /path/to/project

# Simple output format (one line per finding)
python3 project_management/00_tools/find_broken_refs.py --format simple

# JSON output format (one JSON object per line)
python3 project_management/00_tools/find_broken_refs.py --format json
```

#### Options

| Option | Description |
|--------|-------------|
| `--workspace PATH` | Specify workspace root directory (default: auto-detected) |
| `--verbose`, `-v` | Show detailed output including how paths were resolved (only for full format) |
| `--format {full,simple,json}` | Output format: `full` (default, human-readable), `simple` (concise), `json` (JSON lines) |

#### How It Works

**Step 1: File Discovery**
- Scans all searchable files in the workspace (`.md`, `.txt`, `.py`, `.json`, etc.)
- Excludes common directories like `.git`, `node_modules`, build outputs
- Reports total number of files to search

**Step 2: Reference Extraction**
- Parses each file line-by-line to extract potential file references
- Detects multiple reference formats:
  - **Markdown links**: `[text](path/to/file.md)`
  - **Quoted paths**: `"path/to/file.txt"` or `'path/to/file.txt'`
  - **Backtick paths**: `` `path/to/config.yaml` ``
  - **Plain paths**: `path/to/file.py` (with file extension)

**Step 3: Path Resolution**
- Tries multiple resolution strategies for each reference:
  1. Relative to the source file's directory
  2. Relative to workspace root
  3. As absolute path (if provided)
- Uses the first candidate that exists

**Step 4: Existence Check**
- Verifies whether the resolved path exists on the filesystem
- Records references that point to non-existent files

**Step 5: Results Report**
- Groups broken references by source file
- Shows line number, reference type, and referenced path
- Provides summary statistics by reference type
- Returns exit code 1 if broken references found (useful for CI/CD)

#### Output Formats

The tool supports three output formats via the `--format` option:

**Full format** (default, `--format full`):
```
=== Broken References ===

test.md
───────
  Line    4 [markdown_link ]: docs/missing.md
  Line    5 [quoted_path   ]: path/to/missing.txt
  Line    6 [backtick_path ]: config/missing.yaml

════════════════════════════════════════════════════════════
Summary: 3 broken reference(s) in 1 file(s)
════════════════════════════════════════════════════════════
```

**Simple format** (`--format simple`):
One line per finding: `<file> <tangledRef>`
```
test.md docs/missing.md
test.md path/to/missing.txt
test.md config/missing.yaml
```
Best for: scripting, piping to other tools, concise output

**JSON format** (`--format json`):
One JSON object per line (JSON Lines format):
```json
{"file": "test.md", "tangledRef": "docs/missing.md", "line": 4, "type": "markdown_link"}
{"file": "test.md", "tangledRef": "path/to/missing.txt", "line": 5, "type": "quoted_path"}
{"file": "test.md", "tangledRef": "config/missing.yaml", "line": 6, "type": "backtick_path"}
```
Best for: parsing with `jq`, programmatic processing, detailed analysis

**Verbose mode** (only with full format):
Add `--verbose` to show path resolution details:
```
test.md
───────
  Line    4 [markdown_link ]: docs/missing.md
              → Resolved to: /full/path/to/docs/missing.md
              → File does not exist
```

#### File Type Support

The script searches these file types by default:

**Documentation**: `.md`, `.txt`, `.rst`, `.adoc`  
**Code**: `.py`, `.js`, `.ts`, `.java`, `.cpp`, `.c`, `.h`  
**Config**: `.json`, `.yaml`, `.yml`, `.toml`, `.ini`, `.cfg`  
**Web**: `.html`, `.xml`, `.css`, `.scss`  
**Shell**: `.sh`, `.bash`, `.zsh`

#### Best Practices

1. **Run regularly** during development to catch broken references early
2. **Use in CI/CD** to prevent merging broken documentation
3. **Review false positives** - URLs and example paths will be flagged
4. **Use `--verbose`** when debugging specific reference issues
5. **Run after restructuring** to ensure all references were updated
6. **Filter results** if needed using standard Unix tools (grep, awk)

#### Examples

**Example 1: Quick workspace scan**
```bash
python3 project_management/00_tools/find_broken_refs.py
```

**Example 2: Detailed troubleshooting**
```bash
python3 project_management/00_tools/find_broken_refs.py --verbose
```

**Example 3: Simple output for scripting**
```bash
# Get simple list of broken references
python3 project_management/00_tools/find_broken_refs.py --format simple

# Count broken references per file
python3 project_management/00_tools/find_broken_refs.py --format simple | cut -d' ' -f1 | sort | uniq -c

# Find all broken markdown files
python3 project_management/00_tools/find_broken_refs.py --format simple | grep '\.md$'
```

**Example 4: JSON output for programmatic processing**
```bash
# Get JSON output
python3 project_management/00_tools/find_broken_refs.py --format json

# Use jq to filter markdown links only
python3 project_management/00_tools/find_broken_refs.py --format json | jq 'select(.type == "markdown_link")'

# Count by reference type
python3 project_management/00_tools/find_broken_refs.py --format json | jq -r '.type' | sort | uniq -c
```

**Example 5: CI/CD integration**
```bash
# In your CI pipeline
python3 project_management/00_tools/find_broken_refs.py
# Script exits with code 1 if broken refs found, failing the build
```

**Example 6: Filter specific files**
```bash
# Only show .md files with broken refs (simple format)
python3 project_management/00_tools/find_broken_refs.py --format simple | grep '^.*\.md '
```

#### Known Limitations & False Positives

**False Positives** (will be flagged as broken):
- **URLs**: `github.com/user/repo` or `example.com/path`
  - URLs match the path pattern but don't exist as local files
- **Example paths**: Documentation showing path examples
- **JSON keys**: Config keys like `editor.formatOnSave` with dots
- **Generated files**: References to files created at build time

**Actual Limitations**:
- **Encoding**: Requires UTF-8 compatible files (uses `errors='ignore'`)
- **Line-based parsing**: References spanning multiple lines won't be detected
- **Anchor links**: `file.md#section` - anchors are stripped before validation
- **External references**: Only checks workspace-relative paths
- **Case sensitivity**: Path matching is case-sensitive on Linux
- **Symlinks**: Doesn't validate symlink targets

#### Filtering False Positives

The tool reports everything it finds to ensure no real broken references are missed. You can filter results using standard tools:

**With full format:**
```bash
# Exclude URLs (containing .com, .org, etc.)
python3 project_management/00_tools/find_broken_refs.py | grep -v "\.com\|\.org"

# Only show markdown files with issues
python3 project_management/00_tools/find_broken_refs.py | grep "\.md$" -A 10

# Count broken refs per file
python3 project_management/00_tools/find_broken_refs.py | grep "^[^ ]" | wc -l
```

**With simple format (easier filtering):**
```bash
# Exclude URLs
python3 project_management/00_tools/find_broken_refs.py --format simple | grep -v "\.com\|\.org"

# Only markdown files
python3 project_management/00_tools/find_broken_refs.py --format simple | grep '\.md '

# Group by file
python3 project_management/00_tools/find_broken_refs.py --format simple | cut -d' ' -f1 | sort | uniq -c
```

**With JSON format (most flexible):**
```bash
# Filter by type using jq
python3 project_management/00_tools/find_broken_refs.py --format json | jq 'select(.type == "markdown_link")'

# Exclude specific patterns
python3 project_management/00_tools/find_broken_refs.py --format json | jq 'select(.tangledRef | test("\\.com|\\.org") | not)'

# Get unique files with issues
python3 project_management/00_tools/find_broken_refs.py --format json | jq -r '.file' | sort -u
```

#### Troubleshooting

**Problem**: High number of false positives  
**Solution**: 
- URLs and example paths in documentation are expected
- Use grep to filter known patterns
- Review the context - broken refs in TOOLS.md examples are usually intentional

**Problem**: Missing expected broken references  
**Solution**:
- Check that the source file has a searchable extension
- Verify the file isn't in an excluded directory
- Try `--verbose` to see how paths are being resolved
- Ensure the reference has a file extension (required for plain path detection)

**Problem**: "File does not exist" but the file exists  
**Solution**:
- Path might be using the wrong case (Linux is case-sensitive)
- Reference might use `\` on Linux (should use `/`)
- File might be outside the workspace
- Use `--verbose` to see the resolved path

#### Integration Ideas

**Pre-commit hook:**
```bash
#!/bin/bash
python3 project_management/00_tools/find_broken_refs.py
if [ $? -ne 0 ]; then
    echo "Fix broken references before committing"
    exit 1
fi
```

**GitHub Actions:**
```yaml
- name: Check for broken references
  run: |
    python3 project_management/00_tools/find_broken_refs.py
    if [ $? -eq 1 ]; then
      echo "::error::Broken references detected"
      exit 1
    fi
```

#### Technical Details

**Language**: Python 3.7+  
**Dependencies**: Standard library only (no external packages required)  
**Entry point**: `find_broken_refs.py`  
**Key modules**: `pathlib`, `re`, `argparse`, `os`, `sys`, `collections`  
**Exit codes**: 0 = no broken refs, 1 = broken refs found

---

## Contributing New Tools

When adding new tools to this directory:

1. Create the tool script with a descriptive name
2. Add execution permissions: `chmod +x tool_name.py`
3. Include comprehensive `--help` documentation
4. Update this `TOOLS.md` file with tool documentation
5. Follow the documentation template structure shown above
6. Add usage examples relevant to project workflows
