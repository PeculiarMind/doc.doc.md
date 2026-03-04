## Filtering Logic

**Author:** Architect Agent  
**Created on:** 2026-03-01  
**Last Updated:** 2026-03-04  
**Status:** Accepted


**Version History**  
| Date       | Author       | Description                |
|------------|--------------|----------------------------|
| 2026-03-01 | Architect Agent | Initial concept creation from legacy documentation |
| 2026-03-04 | developer.agent | Updated MIME matching pseudocode and routing notes to reflect actual FEATURE_0007 implementation (DEBTR_002) |

**Table of Contents:**  
- [Problem Statement](#problem-statement)
- [Scope](#scope)
- [Proposed Solution](#proposed-solution)
- [Benefits](#benefits)
- [Challenges and Risks](#challenges-and-risks)
- [Implementation Plan](#implementation-plan)
- [Conclusion](#conclusion)
- [References](#references)


### Problem Statement
The system needs a flexible and powerful mechanism to control which files should be processed and which should be excluded from documentation generation. Users must be able to specify complex filtering criteria based on file extensions, paths, and MIME types, with intuitive boolean logic to combine multiple filter conditions.

### Scope
This concept defines how file filtering operates in the doc.doc.md system, including the types of filters supported, the boolean logic for combining filter criteria, and the evaluation algorithm.

### In Scope
- File extension-based filtering (e.g., `.pdf`, `.txt`, `.md`)
- Glob pattern-based filtering (e.g., `**/2024/**`, `**/temp/**`)
- MIME type-based filtering (e.g., `application/pdf`, `text/plain`)
- Boolean logic for combining include filters (OR within parameter, AND between parameters)
- Boolean logic for combining exclude filters (OR within parameter, AND between parameters)
- Filter evaluation algorithm
- Examples demonstrating filter behavior

### Out of Scope
- Content-based filtering (filtering based on file contents)
- Size-based filtering (filtering by file size)
- Date-based filtering (filtering by modification/creation dates)
- Regular expression filtering
- User interface for filter configuration

### Proposed Solution

#### Filter Criteria Types

The system supports three types of filter criteria:

1. **File Extensions**: Match files by extension (e.g., `.pdf`, `.txt`, `.md`)
2. **Glob Patterns**: Match files by path pattern (e.g., `**/2024/**`, `**/temp/**`)
3. **MIME Types**: Match files by MIME type, with optional glob wildcard support (e.g., `application/pdf`, `text/plain`, `image/*`, `text/*`)

#### Criterion Routing in doc.doc.sh

Before evaluation begins, `doc.doc.sh` splits all user-supplied filter criteria into two groups:

- **Path criteria** — used for the initial `find`-based file discovery pass. A criterion is classified as a path criterion when it contains `**` (recursive glob) or contains no `/` at all (e.g., `.pdf`, `**/2024/**`).
- **MIME criteria** — applied after the `file` plugin detects the MIME type for each file. A criterion is classified as a MIME criterion when it contains `/` but does **not** contain `**` (e.g., `application/pdf`, `image/*`, `text/*`).

MIME criteria are evaluated in a dedicated *MIME filter gate* that runs immediately after the `file` plugin executes. The `file` plugin emits the detected MIME type as the `mimeType` field in its JSON output. `doc.doc.sh` extracts this value and pipes it as a single line to `filter.py` stdin, passing the MIME criteria as `--include`/`--exclude` arguments. Because `filter.py` treats all non-extension, non-`**` values as glob patterns (matched with `fnmatch`), both literal MIME strings and wildcard MIME patterns (e.g., `image/*`) are evaluated consistently with no MIME-specific code path in `filter.py` itself.

#### Boolean Logic for Filters

**Include Filter Logic:**

- **Within a single `--include` parameter** (comma-separated values):
  - Values are **ORed** together
  - A file matches if it satisfies **at least one** criterion
  - Example: `--include ".pdf,.txt"` → matches `.pdf` OR `.txt`

- **Between multiple `--include` parameters**:
  - Parameters are **ANDed** together
  - A file must match **at least one criterion from each** parameter
  - Example:
    ```bash
    --include ".pdf,.txt" --include "**/2024/**"
    # File must be (.pdf OR .txt) AND (in 2024 directory)
    ```

**Exclude Filter Logic:**

- **Within a single `--exclude` parameter** (comma-separated values):
  - Values are **ORed** together
  - A file is excluded if it matches **at least one** criterion
  - Example: `--exclude ".log,.tmp"` → excludes `.log` OR `.tmp`

- **Between multiple `--exclude` parameters**:
  - Parameters are **ANDed** together
  - A file is excluded only if it matches **at least one criterion from each** parameter
  - Example:
    ```bash
    --exclude ".log" --exclude "**/temp/**"
    # File excluded only if (.log) AND (in temp directory)
    ```

#### Filter Evaluation Algorithm

The filter algorithm runs in two distinct passes:

**Pass 1 — Path filtering** (performed by `filter.py` operating on file paths):

```python
def should_process_file(file_path, include_params, exclude_params):
    """
    Determine if a file should be processed based on include/exclude filters.
    
    Args:
        file_path: Path to the file (or MIME type string when invoked for MIME gate)
        include_params: List of include parameter strings (comma-separated criteria)
        exclude_params: List of exclude parameter strings (comma-separated criteria)
    
    Returns:
        bool: True if file should be processed
    """
    # If no include filters, include all files by default
    if not include_params:
        include_match = True
    else:
        # All include parameters must match (AND between parameters)
        include_match = all(
            # At least one criterion per parameter must match (OR within parameter)
            any(matches_criterion(file_path, criterion) 
                for criterion in param.split(','))
            for param in include_params
        )
    
    # If no exclude filters, exclude nothing by default
    if not exclude_params:
        exclude_match = False
    else:
        # All exclude parameters must match to exclude (AND between parameters)
        exclude_match = all(
            # At least one criterion per parameter must match (OR within parameter)
            any(matches_criterion(file_path, criterion)
                for criterion in param.split(','))
            for param in exclude_params
        )
    
    # Include if matches include criteria and does not match exclude criteria
    return include_match and not exclude_match

def matches_criterion(value, criterion):
    """Check if a value (file path or MIME type string) matches a single criterion."""
    criterion = criterion.strip()
    
    # Extension match
    if criterion.startswith('.'):
        return value.endswith(criterion)
    
    # Glob pattern match (handles path globs and MIME glob patterns such as image/*)
    return fnmatch.fnmatch(value, criterion)
```

**Pass 2 — MIME filter gate** (performed by `doc.doc.sh` after the `file` plugin runs):

`doc.doc.sh` extracts the `mimeType` value emitted by the `file` plugin and invokes `filter.py` again, this time feeding the MIME type string as stdin. The MIME criteria (criteria containing `/` but not `**`) are passed as `--include`/`--exclude` arguments. `filter.py` is stateless and general-purpose: it does not distinguish between path and MIME invocations — `fnmatch` handles both cases equally.

```bash
# Pseudocode for the MIME filter gate in doc.doc.sh
mime_type=$(extract_mime_type_from_plugin_output)
echo "$mime_type" | python3 filter.py --include "image/*" --include "text/plain"
# Non-empty output → MIME criteria satisfied; empty output → file skipped
```

#### Filter Examples

| Include Params | Exclude Params | File | Result | Reason |
|----------------|----------------|------|--------|--------|
| `.pdf,.txt` | None | `doc.pdf` | ✅ Include | Matches `.pdf` |
| `.pdf,.txt` | None | `data.csv` | ❌ Exclude | Doesn't match `.pdf` or `.txt` |
| `.pdf`, `**/2024/**` | None | `2024/doc.pdf` | ✅ Include | `.pdf` AND `**/2024/**` |
| `.pdf`, `**/2024/**` | None | `2023/doc.pdf` | ❌ Exclude | `.pdf` but NOT `**/2024/**` |
| `.pdf,.txt` | `.txt` | `doc.txt` | ❌ Exclude | Matches include but also exclude |
| `.pdf,.txt` | `.log`, `**/temp/**` | `temp/file.csv` | ✅ Include | Not excluded (doesn't match both exclude params) |
| `.pdf,.txt` | `.log`, `**/temp/**` | `temp/debug.log` | ❌ Exclude | Matches both `.log` AND `**/temp/**` |
| `image/*` | None | MIME `image/jpeg` | ✅ Include | `fnmatch("image/jpeg", "image/*")` matches |
| `image/*` | None | MIME `text/plain` | ❌ Exclude | `fnmatch("text/plain", "image/*")` does not match |
| `text/*` | `text/csv` | MIME `text/plain` | ✅ Include | Matches `text/*` and does not match `text/csv` |
| `text/*` | `text/csv` | MIME `text/csv` | ❌ Exclude | Matches both include `text/*` and exclude `text/csv` |

### Benefits
- **Flexibility**: Supports multiple types of filter criteria (extensions, patterns, MIME types)
- **Expressiveness**: Complex filtering logic through boolean combinations
- **Intuitive**: OR within parameters, AND between parameters is natural and predictable
- **User-friendly**: Simple syntax for common cases, powerful for advanced needs
- **Performance**: Early filtering reduces unnecessary file processing

### Challenges and Risks
- **Complexity**: The AND/OR logic may be confusing for some users initially
- **Performance**: Pattern matching on large directory trees could be slow
- **Edge cases**: Complex filter combinations may produce unexpected results
- **Documentation**: Requires clear examples to help users understand the logic
- **Testing**: Need comprehensive test coverage for all filter combinations

### Implementation Plan
1. **Phase 1**: Implement basic extension filtering with single include/exclude parameters
2. **Phase 2**: Add glob pattern support
3. **Phase 3**: Add MIME type detection and filtering
4. **Phase 4**: Implement multiple parameter support with AND/OR logic
5. **Phase 5**: Optimize performance with short-circuit evaluation
6. **Phase 6**: Add comprehensive unit tests and integration tests
7. **Phase 7**: Create user documentation with examples

### Conclusion
The filtering logic concept provides a powerful and flexible way to control which files are processed by doc.doc.md. By supporting multiple filter criteria types and intuitive boolean logic, users can precisely define which files to include or exclude from documentation generation. The proposed solution balances simplicity for common use cases with expressiveness for complex filtering requirements.

### References
- Glob pattern matching: Python `fnmatch` module documentation
- MIME type detection strategies
