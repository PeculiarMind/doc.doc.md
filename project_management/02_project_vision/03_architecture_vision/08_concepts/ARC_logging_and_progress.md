## Logging and Progress Indication

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
When processing large numbers of files, users need feedback about what the system is doing, how long it might take, and what problems (if any) occurred. Without proper logging and progress indication, users cannot tell if the system is working, stuck, or encountering errors. Clear, informative output helps users understand system behavior and diagnose issues.

### Scope
This concept defines the logging and progress indication strategy for doc.doc.md, including log levels, progress output format, and user feedback mechanisms.

### In Scope
- Log level definitions (ERROR, WARN, INFO, DEBUG)
- Progress bar implementation and updates
- File processing status messages
- Summary statistics (processed, skipped, errors)
- Console output formatting
- Log level filtering and control
- Real-time progress updates

### Out of Scope
- Log file persistence
- Structured logging (JSON logs)
- Log rotation or management
- Remote logging or monitoring
- Performance metrics collection
- Detailed timing breakdowns
- Log aggregation across multiple runs

### Proposed Solution

#### Log Levels

The system uses four standard log levels:

- **ERROR**: Critical issues preventing operation
  - Failed to read configuration
  - System errors (disk full, permissions)
  - Unrecoverable plugin failures

- **WARN**: Non-critical issues, operation continues
  - Plugin missing dependencies (plugin skipped)
  - File access errors (file skipped)
  - Missing template variables

- **INFO**: General information about progress (default)
  - Processing started/completed
  - File processing status
  - Summary statistics

- **DEBUG**: Detailed diagnostic information
  - Plugin execution details
  - Dependency resolution steps
  - Template variable substitution
  - File filter evaluation

#### Progress Output

The system displays real-time progress with a visual progress bar:

```
Processing documents...
[████████████████████████████░░░░] 75% (30/40 files)

Processed: /input/docs/report1.pdf → /output/docs/report1.md
Processed: /input/docs/report2.pdf → /output/docs/report2.md
Skipped: /input/logs/debug.log (excluded by filter)

Complete! 30 files processed, 5 skipped, 5 errors
```

**Components:**
1. **Progress bar**: Visual indicator with percentage
2. **File counter**: Current/total files
3. **Status messages**: Individual file processing results
4. **Summary**: Final statistics

#### Output Format

**INFO level (default):**
- Progress bar updated in place (same line)
- One line per processed file
- Summary at completion
- Minimal clutter

**DEBUG level:**
- All INFO output
- Plugin execution details
- Filter evaluation results
- Variable substitution details
- Timing information

**WARN level:**
- Warnings displayed with yellow highlight
- File path and reason
- Suggestion for resolution

**ERROR level:**
- Errors displayed with red highlight
- Full error details
- Location and hint
- Immediate display (not buffered)

#### Progress Bar Behavior

- **Updates**: Every file processed (or every N seconds for slow files)
- **Format**: `[████░░░░] XX% (N/Total files)`
- **Terminal detection**: Only show if stdout is a terminal
- **Fallback**: Simple text updates if progress bar not supported

#### Verbosity Control

Users can control output verbosity:

```bash
# Default (INFO)
doc.doc.md /input /output

# Quiet (errors only)
doc.doc.md /input /output --quiet

# Verbose (DEBUG)
doc.doc.md /input /output --verbose

# Debug with timestamp
doc.doc.md /input /output --verbose --timestamp
```

#### Summary Statistics

Final summary includes:
- Total files found
- Files processed successfully
- Files skipped (by filter)
- Files with errors
- Total processing time
- Average time per file (in verbose mode)

Example:
```
Complete! 
  Processed: 30 files
  Skipped:   5 files (filter)
  Errors:    5 files
  Time:      12.5 seconds
```

### Benefits
- **User feedback**: Clear indication of progress and status
- **Transparency**: Users understand what the system is doing
- **Debugging**: Verbose mode helps diagnose issues
- **Confidence**: Progress bar shows system is working
- **Summary**: Statistics help evaluate results
- **Flexible**: Different verbosity levels for different needs

### Challenges and Risks
- **Performance**: Progress updates could slow processing
- **Terminal compatibility**: Progress bars may not work in all terminals
- **Output management**: Balancing detail with readability
- **Buffer issues**: Ensuring errors appear immediately
- **Thread safety**: If parallel processing is added later
- **Screen size**: Long paths may wrap or truncate

### Implementation Plan
1. **Phase 1**: Implement basic logging with ERROR, WARN, INFO levels
2. **Phase 2**: Add file processing status messages
3. **Phase 3**: Implement progress counter (N/Total format)
4. **Phase 4**: Add progress bar for terminal output
5. **Phase 5**: Implement DEBUG level logging
6. **Phase 6**: Add summary statistics
7. **Phase 7**: Implement verbosity flags (--quiet, --verbose)
8. **Phase 8**: Add timestamp option
9. **Phase 9**: Optimize progress updates for performance
10. **Phase 10**: Test on various terminal types

### Conclusion
Effective logging and progress indication significantly improve user experience by providing clear feedback about system operation. The combination of progress bars, status messages, and configurable verbosity levels allows doc.doc.md to serve both casual users who want simple feedback and power users who need detailed diagnostics. The design balances informativeness with performance and terminal compatibility.

### References
- Original concepts documentation: [08_concepts_old.md](08_concepts_old.md)
- Error handling concept: [ARC_error_handling.md](ARC_error_handling.md)
- Terminal progress bar libraries and techniques
- ANSI color codes and terminal control sequences
