# Mixed Bash and Python Implementation Strategy

- **ID:** ADR-001
- **Status:** Draft
- **Created at:** 2026-02-23
- **Created by:** Architect Agent
- **Obsoleted by:** N/A

# TOC

1. [Context](#context)
2. [Decision](#decision)
3. [Consequences](#consequences)
4. [Evaluation Matrix](#evaluation-matrix)
5. [Alternatives Considered](#alternatives-considered)
6. [References](#references)

# Context

The doc.doc.md project is a command-line tool designed to process document collections in directory structures and generate markdown files. The system has several distinct functional requirements:

## Core Requirements

1. **CLI Interface and Orchestration:**
   - Parse command-line arguments with multiple options (`--input-directory`, `--output-directory`, `--template`, `--include`, `--exclude`)
   - Coordinate workflow execution across multiple components
   - Manage plugin lifecycle (list, activate, deactivate, install)
   - Provide clear user feedback via help system, logging, and progress indication

2. **Complex Filtering Logic:**
   - Handle include/exclude filters with AND/OR operators
   - Support multiple filter types: file extensions (`.pdf`, `.txt`), glob patterns (`**/2024/**`), and MIME types (`application/pdf`)
   - Multiple `--include` parameters are ANDed together (file must match at least one criterion from each parameter)
   - Values within a single `--include` parameter are ORed together
   - Same logic applies to `--exclude` parameters

3. **File Processing:**
   - Traverse directory structures efficiently
   - Determine MIME types reliably across platforms
   - Match complex glob patterns and path criteria
   - Execute plugins in dependency order for each file

4. **Plugin System:**
   - Discover available plugins
   - Manage plugin dependencies
   - Execute plugins with proper error handling
   - Support future extensibility

## Technical Challenges

- **Filtering Complexity:** The AND/OR logic for combining multiple include/exclude criteria with different filter types (extensions, globs, MIME types) requires robust parsing and evaluation - this is the primary driver for Python usage
- **Cross-Platform Compatibility:** The tool should work on Linux, macOS, and potentially Windows (via WSL/Git Bash)
- **Plugin Orchestration:** Managing plugin discovery, dependency resolution, and execution order via shell command invocation
- **User Experience:** Fast startup time, responsive CLI, clear error messages, and progress feedback
- **Language-Agnostic Plugin System:** Plugins invoked via shell commands (not direct imports), allowing any language while maintaining simple shell-based interface

## Technical Non-Challenges

- **MIME Type Detection:** Delegated to the dedicated `file` plugin which wraps the standard `file` command - not a factor in the Bash vs Python decision

# Decision

**We will implement doc.doc.md using a mixed Bash and Python approach**, with clear separation of responsibilities:

## Bash Components

**Bash will handle CLI orchestration, user interaction, and system-level operations:**

- **Main entry point** (`doc.doc.sh`): Command-line argument parsing, help display, top-level workflow coordination
- **Component scripts** (`components/*.sh`):
  - `help.sh` - Help system and documentation
  - `logging.sh` - User-facing log messages and progress indication
  - `plugins.sh` - Plugin discovery, activation/deactivation, and orchestration
  - `templates.sh` - Template file management
- **Plugin invocation**: Plugins are executed as shell commands (from `descriptor.json`); they may be Bash scripts, Python scripts, or any executable - invocation is always via shell command execution, never direct Python imports
- **File system operations**: Directory traversal with `find`, file discovery, path operations
- **Process coordination**: Invoking Python scripts at appropriate workflow stages
- **Pipeline orchestration**: Connecting `find`, Python filters, and plugin execution via Unix pipes

## Python Components

**Python will handle complex logic that is difficult to implement reliably in Bash:**

- **Filter evaluation engine**: Parse and evaluate complex include/exclude logic with AND/OR operators across multiple `--include` and `--exclude` parameters
- **Glob pattern matching**: Advanced path matching beyond basic shell globs (e.g., `**/2024/**/*.pdf`)
- **Data transformation and formatting**: Prepare data structures for template rendering
- **Plugin internal logic** (optional): Plugins may use Python for complex processing, called from their Bash entry point
- **Future extensibility**: Foundation for additional complex features (metadata extraction, content analysis, etc.)

**Python will NOT handle:**
- Plugin invocation (plugins executed as shell commands, not Python imports)
- MIME type detection (handled by dedicated `file` plugin using the `file` command)
- CLI argument parsing (handled by Bash entry point)
- Direct user interaction (always wrapped by Bash)

## Integration Points

**Unix Pipeline Architecture:**

- **Invocation pattern**: Bash uses `find` to discover files, pipes to Python for filtering, processes results
- **Data format**: Null-delimited file paths (`\0`) for safe handling of special characters
- **IPC mechanism**: Standard Unix pipes with null-delimited streams
- **Filtering stage**: Single upfront filter before files are handed to plugins (performance is not a constraint; batch processing is acceptable)

**Example workflow:**
```bash
find "$INPUT_DIR" -type f -print0 | \
  python3 components/filter.py \
    --include-ext "pdf,txt" \
    --exclude-path "*/temp/*" \
    -0 | \
  while IFS= read -r -d '' file; do
    # Process through plugin chain
  done
```

**Plugin Architecture:**
- **Invocation method**: Plugins are invoked via shell command execution (e.g., `bash main.sh` or `python3 process.py`)
- **Language-agnostic**: Plugins define their command in `descriptor.json`; the command is executed via the shell
- **No direct imports**: Core system never imports or calls plugins directly from Python - always via shell command
- **Examples**:
  - Bash plugin: `"command": "main.sh {FILE_PATH}"`
  - Python plugin: `"command": "python3 process.py {FILE_PATH}"`
  - Any executable: `"command": "./custom_binary {FILE_PATH}"`

**Technical Specifications:**
- **Minimum Python version**: Python 3.12+ (latest stable, modern features)
- **Exit codes**: Standard Unix conventions (0 = success, non-zero = failure)
- **Error handling**: Python writes errors to stderr, Bash propagates to user

# Consequences

## Positive

1. **Leverage Language Strengths:**
   - Bash excels at CLI scripting, file operations, and process orchestration - natural fit for the entry point and system integration
   - Python excels at complex logic, robust parsing, and cross-platform library support - ideal for filtering and processing

2. **Familiar User Experience:**
   - Bash entry point provides traditional CLI tool UX expected by Unix/Linux users
   - Help system, logging, and error messages in native shell style

3. **Maintainability:**
   - Clear separation of concerns: orchestration (Bash) vs. complex logic (Python)
   - Each language used for tasks it handles best
   - Easier to test individual components (unit tests in Python, integration tests in Bash)

4. **Extensibility:**
   - Plugins can be written in any language (Bash, Python, compiled binaries, etc.)
   - Plugin interface is simple: shell command execution with defined inputs/outputs via `descriptor.json`
   - Future enhancements can be added in the most appropriate language
   - Python libraries available for complex file format parsing (PDF, DOCX, etc.)

5. **Performance:**
   - Bash handles file discovery and traversal efficiently
   - Python only invoked for complex filtering and processing where needed
   - No overhead of starting heavy frameworks

6. **Cross-Platform:**
   - Bash available on all Unix-like systems and Windows (WSL/Git Bash)
   - Python widely available and easy to install
   - Both have broad ecosystem support

## Negative

1. **Dual Runtime Dependencies:**
   - Users must have both Bash and Python 3.12+ installed
   - Python 3.12+ requirement may exclude older systems (Ubuntu 24.04+ / Debian 13+)
   - Increased installation complexity compared to single-language solution

2. **Inter-Process Communication Overhead:**
   - Python process startup cost (mitigated by single invocation per run)
   - Null-delimited stream processing requires careful handling
   - For extremely large file sets (100k+ files), memory usage may be a consideration

3. **Testing Complexity:**
   - Integration tests must span both languages
   - Mock/stub boundaries more complex
   - Debugging across language boundaries can be challenging

4. **Learning Curve:**
   - Core contributors need familiarity with both Bash and Python
   - Plugin authors can use any language but must provide shell-invocable interface
   - Code review requires expertise in multiple languages
   - Documentation must cover both ecosystems

5. **Deployment Complexity:**
   - Package managers must handle both Bash and Python dependencies
   - Python virtual environment considerations
   - Multiple sets of dependencies to manage

6. **Error Handling:**
   - Error propagation across language boundaries requires careful design
   - Stack traces may be split across Bash and Python
   - Consistent error message formatting needs coordination

# Evaluation Matrix

The following matrix compares all considered implementation approaches across key decision criteria with weighted scoring:

| Criterion | Weight | **Mixed Bash+Python** (✓) | Pure Bash | Pure Python | Bash+Unix Tools | Bash+Compiled |
|-----------|--------|---------------------------|-----------|-------------|-----------------|---------------|
| **Filter Logic Complexity** | 1.0 | ✓ Excellent (Python) | ✗ Very difficult | ✓ Excellent | ✗ Nearly impossible | ✓ Excellent |
| **Unix CLI UX** | 1.0 | ✓ Native Bash feel | ✓ Perfect | ~ Less idiomatic | ✓ Perfect | ✓ Native Bash feel |
| **Plugin Language Flexibility** | 1.0 | ✓ Any (shell-invoked) | ✓ Any (shell-invoked) | ~ Python or subprocess | ✓ Any (shell-invoked) | ✓ Any (shell-invoked) |
| **Runtime Dependencies** | 0.1 | ~ Bash + Python 3.12+ | ✓ Bash only | ✓ Python only | ✓ Bash + standard tools | ✓ Bash only |
| **Installation Complexity** | 0.1 | ~ Moderate | ✓ Minimal | ✓ Simple | ✓ Minimal | ~ Platform-specific binaries |
| **Maintainability** | 0.5 | ✓ Good separation | ~ Hard filter logic | ✓ Excellent | ✗ Unreadable filters | ✓ Excellent |
| **Development Speed** | 1.0 | ✓ Fast iteration | ~ Slow for filters | ✓ Very fast | ✗ Error-prone | ~ Build step slows |
| **Performance** | 0.1 | ✓ Good (1x Python call) | ✓ Excellent | ~ Startup overhead | ✓ Excellent | ✓ Excellent |
| **Cross-Platform** | 0.5 | ✓ Bash+Python ubiquitous | ✓ Bash everywhere | ✓ Python everywhere | ~ Tool availability varies | ~ Cross-compilation needed |
| **Testing Complexity** | 0.5 | ~ Cross-language tests | ✓ Bash tests only | ✓ Python tests only | ✓ Bash tests only | ~ Cross-language tests |
| **Future Extensibility** | 1.0 | ✓ Python libraries | ~ Limited | ✓ Rich ecosystem | ✗ Very limited | ✓ Good libraries |
| **Contributor Barrier** | 0.5 | ~ Two languages | ✓ Shell scripting only | ✓ Python only | ✓ Shell scripting only | ✗ Compiled language + Bash |
| **Distribution** | 1.0 | ✓ Simple (scripts) | ✓ Simple (scripts) | ✓ Simple (scripts) | ✓ Simple (scripts) | ✗ Architecture-specific |
| **Weighted Score** | **/8.3** | **7.70** (93%) | **6.05** (73%) | **7.25** (87%) | **4.55** (55%) | **5.75** (69%) |

**Legend:**
- ✓ = Strength / Good fit (1.0 point)
- ~ = Acceptable / Trade-off (0.5 points)
- ✗ = Weakness / Poor fit (0.0 points)
- **Weighted Score** = Sum of (rating × weight) across all criteria

**Decision Rationale:** Mixed Bash+Python scores highest (7.70/8.3, 93%) by providing the best balance between Unix CLI UX (Bash orchestration), complex logic handling (Python filtering), and plugin flexibility (shell command invocation). Pure Python (7.25/8.3, 87%) is close but loses the natural shell integration expected from CLI tools. The dual dependency trade-off is justified by avoiding unmaintainable Bash filter logic while preserving the shell scripting philosophy.

# Alternatives Considered

## Alternative 1: Pure Bash Implementation

**Approach:** Implement entire system in Bash, including complex filtering logic.

**Pros:**
- Single runtime dependency
- Native performance for file operations
- Familiar to shell scripting audience
- No IPC overhead

**Cons:**
- Complex filtering logic very difficult in Bash (AND/OR operators, multiple filter types)
- String manipulation and parsing cumbersome for filter evaluation
- Limited library ecosystem for future enhancements (data transformation, metadata extraction)
- Error handling and data structures less robust than Python

**Rejection Reason:** The complex filtering logic requirements (especially AND/OR combinations of include/exclude with multiple filter types) would be extremely difficult to implement reliably and maintainably in pure Bash. The evaluation logic alone would require extensive conditional chains that would be error-prone and difficult to test.

## Alternative 2: Pure Python Implementation

**Approach:** Implement entire system in Python, including CLI and orchestration.

**Pros:**
- Single runtime dependency
- Excellent libraries for everything (argparse, pathlib, python-magic, etc.)
- Robust error handling and testing frameworks
- Easier to maintain and extend
- Rich ecosystem for future enhancements

**Cons:**
- Less natural for Unix CLI tools
- Startup overhead for simple operations
- Python might not be pre-installed on all systems
- Shell integration features (pipes, redirects) less idiomatic
- Larger installation footprint

**Rejection Reason:** While Python would handle complex logic excellently, using Bash for orchestration and shell command execution maintains the Unix CLI tool philosophy. A pure Python implementation would require either subprocess calls to invoke plugins (awkward) or a Python-based plugin API (limiting language choice). The shell-based plugin invocation model keeps the system simple and language-agnostic: **plugins are executed as shell commands**, allowing any language while maintaining a consistent, simple interface.

## Alternative 3: Bash with External Unix Tools Only

**Approach:** Use Bash with standard Unix tools (`find`, `file`, `grep`, `awk`, etc.) to avoid Python dependency.

**Pros:**
- No additional runtime dependencies beyond standard Unix tools
- Very lightweight
- Maximum compatibility
- Fast execution

**Cons:**
- Complex filtering logic extremely difficult with `awk`/`sed` alone
- AND/OR combinations of multiple filter types nearly impossible to express cleanly
- Future extensibility severely limited
- Code would be very difficult to read and maintain
- Testing complex awk/sed pipelines is error-prone

**Rejection Reason:** While this approach minimizes dependencies, the complexity of the filtering requirements would result in unmaintainable shell code. The AND/OR logic alone would require extensive conditional chains that would be error-prone and difficult to test.

## Alternative 4: Bash + Compiled Language (Go/Rust)

**Approach:** Use Bash for CLI, compiled helper binary (Go/Rust) for complex processing.

**Pros:**
- Fast execution (no Python startup overhead)
- Single binary distribution for helper
- Type safety and robustness
- No runtime dependencies beyond Bash

**Cons:**
- Must compile for multiple platforms
- Distribution complexity (architecture-specific binaries)
- Higher barrier to contribution (compiled language knowledge)
- Build toolchain requirements
- Slower development iteration

**Rejection Reason:** While performance would be excellent, the added complexity of cross-compiling and distributing platform-specific binaries outweighs the benefits for a document processing tool where startup time is not critical. Python's ubiquity makes it a better choice for ease of installation and contribution.

# References

- [Project Goals](../../01_project_goals/project_goals.md) - Detailed CLI interface and filtering requirements
- [Building Block View](../05_building_block_view/05_building_block_view.md) - High-level component architecture
- [File Plugin](../../../../doc.doc.md/plugins/file/) - MIME type detection using `file` command
- [README.md](../../../../README.md) - User-facing feature description
- Python 3.12 Release Notes: https://docs.python.org/3/whatsnew/3.12.html
- GNU `find` manual (null-delimited output): https://www.gnu.org/software/findutils/manual/html_node/find_html/Safe-File-Name-Handling.html
- Bash read builtin with null delimiter: https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html
