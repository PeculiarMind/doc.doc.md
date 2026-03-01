## Filtering Logic

**Author:** Architect Agent  
**Created on:** 2026-03-01  
**Last Updated:** 2026-03-01  
**Status:** Proposed


**Version History**  
| Date       | Author       | Description                |
|------------|--------------|----------------------------|
| 2026-03-01 | Architect Agent | Initial concept creation from legacy documentation |

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
3. **MIME Types**: Match files by MIME type (e.g., `application/pdf`, `text/plain`)

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

```python
def should_process_file(file_path, include_params, exclude_params):
    """
    Determine if a file should be processed based on include/exclude filters.
    
    Args:
        file_path: Path to the file
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

def matches_criterion(file_path, criterion):
    """Check if file matches a single criterion."""
    criterion = criterion.strip()
    
    # Extension match
    if criterion.startswith('.'):
        return file_path.endswith(criterion)
    
    # MIME type match
    elif '/' in criterion:
        mime_type = get_mime_type(file_path)
        return mime_type == criterion
    
    # Glob pattern match
    else:
        return fnmatch.fnmatch(file_path, criterion)
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
- Original concepts documentation: [08_concepts_old.md](08_concepts_old.md)
- Glob pattern matching: Python `fnmatch` module documentation
- MIME type detection strategies
