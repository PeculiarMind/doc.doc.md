# IDR-0010: Log Level Design (INFO, WARN, ERROR, DEBUG)

**ID**: IDR-0010  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: None (implementation detail not specified in vision)

## Decision

Implement four log levels with conditional display: DEBUG, INFO (verbose only), WARN, ERROR (always shown).

## Context

Logging must serve two audiences:
1. **Regular users**: Want to see errors/warnings only
2. **Debugging users**: Want detailed execution trace

## Rationale

**Level Definitions**:
- **DEBUG**: Detailed diagnostic information (e.g., "Executing plugin: stat")
- **INFO**: Informational messages (e.g., "Detected platform: ubuntu")
- **WARN**: Warning messages (e.g., "Plugin tool not available")
- **ERROR**: Error messages (e.g., "Cannot read directory")

**Display Logic**:
```
Show message IF:
  (VERBOSE flag is true) OR
  (level is WARN) OR
  (level is ERROR)
```

**Output Stream**: All logs → stderr (separates diagnostics from data output)

## Design Principles

1. **Quiet by Default**: Users see errors/warnings only (clean output)
2. **Verbose for Debugging**: `-v` enables INFO and DEBUG messages
3. **Errors Always Shown**: Users always know when something fails
4. **Warnings Always Shown**: Users alerted to degraded functionality

## Implementation

```bash
log() {
  local level="$1"
  local message="$2"
  
  if [[ "${VERBOSE}" == true ]] || [[ "${level}" == "ERROR" ]] || [[ "${level}" == "WARN" ]]; then
    echo "[${level}] ${message}" >&2
  fi
}
```

## Example Outputs

**Normal mode** (quiet):
```bash
$ ./doc.doc.sh -x
[ERROR] Unknown option: -x
```

**Verbose mode**:
```bash
$ ./doc.doc.sh -v
[INFO] Verbose mode enabled
[INFO] Detected platform: ubuntu
[INFO] Script initialization complete
```

## Alternatives Considered

1. **Five levels** (TRACE, DEBUG, INFO, WARN, ERROR): Rejected - Over-engineered for Bash script
2. **Numeric levels**: Rejected - Less readable than named levels
3. **Separate verbose and debug flags**: Rejected - Complexity not justified

## Impact

- Clear separation between user messages and debug output
- Enables troubleshooting without code modification
- Follows industry conventions (similar to syslog levels)

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh:32-49`

```bash
log() {
  local level="$1"
  local message="$2"
  
  # Show DEBUG and INFO only in verbose mode, always show WARN and ERROR
  if [[ "${VERBOSE}" == true ]] || [[ "${level}" == "ERROR" ]] || [[ "${level}" == "WARN" ]]; then
    echo "[${level}] ${message}" >&2
  fi
}
```

**Usage Examples**:
- `detect_platform()`: Lines 126, 128 (INFO)
- `parse_arguments()`: Lines 170, 184 (INFO)
- Error messages: Various locations (ERROR)

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented
