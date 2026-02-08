# Feature: Enhanced Logging Format with Timestamps

**ID**: 0004  
**Type**: Feature Enhancement  
**Status**: Funnel  
**Created**: 2026-02-08  
**Updated**: 2026-02-08  
**Priority**: Low

## Overview
Enhance the logging system to include timestamps and component identifiers in log messages, aligning the implementation with the architecture vision's specified log format.

## Description
The current implementation uses a simplified logging format: `[LEVEL] Message`. The architecture vision specifies a more comprehensive format: `[TIMESTAMP] [LEVEL] [COMPONENT] Message`. This feature will enhance the logging system to include:

- **Timestamps**: ISO 8601 format timestamps for each log entry
- **Component Identification**: Source component/module generating the log message
- **Backward Compatibility**: Maintain readable output for basic use cases
- **Performance**: Minimize overhead from timestamp generation

This enhancement will improve debugging, troubleshooting, and audit capabilities, especially when analyzing logs from longer operations with multiple plugins.

## Business Value
- **Improved Debugging**: Timestamps enable chronological analysis of operations
- **Performance Analysis**: Time-based correlation of events and bottlenecks
- **Audit Trail**: Complete record of when events occurred
- **Production Readiness**: Professional logging suitable for production deployments
- **Architecture Alignment**: Eliminates deviation between vision and implementation

## Related Requirements
- [req_0006](../../01_vision/02_requirements/03_accepted/req_0006_verbose_logging_mode.md) - Verbose Logging Mode
- [req_0009](../../01_vision/02_requirements/03_accepted/req_0009_lightweight_implementation.md) - Lightweight Implementation (consider performance impact)

## Architectural Context

### Current State
- **Implementation**: `[LEVEL] Message` format defined in `scripts/doc.doc.sh`
- **Status**: Functional but simplified for v1.0 release
- **Rationale**: Adequate for current use cases with minimal log volume

### Vision State
- **Architecture Vision**: `[TIMESTAMP] [LEVEL] [COMPONENT] Message` format
- **Location**: `01_vision/03_architecture/08_concepts/08_0003_cli_interface_concept.md`
- **Intent**: Professional logging suitable for production and debugging

### Deviation Analysis
- **Type**: Pragmatic Simplification
- **Impact**: LOW - No negative consequences in current usage
- **Decision**: Documented in architecture sync (2026-02-08)
- **Recommendation**: Add timestamps when analysis features increase log volume

## Acceptance Criteria

### Timestamp Support
- [ ] Log entries include ISO 8601 formatted timestamps (e.g., `2026-02-08T14:30:45`)
- [ ] Timestamp precision is appropriate (seconds sufficient, milliseconds optional)
- [ ] Timestamp generation has minimal performance overhead
- [ ] Timestamps use UTC or local time consistently (document choice)

### Component Identification
- [ ] Log entries identify the source component/module (e.g., `MAIN`, `PLUGIN`, `SCANNER`)
- [ ] Component names are concise (6-8 characters max for alignment)
- [ ] Component identification is automatic based on context
- [ ] Functions accepting component parameter for flexibility

### Format Implementation
- [ ] Log format matches vision: `[TIMESTAMP] [LEVEL] [COMPONENT] Message`
- [ ] All log levels supported: DEBUG, INFO, WARN, ERROR
- [ ] Format is consistent across all logging functions (log_info, log_error, etc.)
- [ ] Log output remains human-readable

### Backward Compatibility
- [ ] Existing log consumers (tests, scripts) still work
- [ ] Help text and documentation updated with new format
- [ ] No breaking changes to script behavior

### Performance
- [ ] Timestamp generation adds <1ms overhead per log entry
- [ ] No noticeable impact on script execution time
- [ ] Benchmarked with high-volume logging scenarios

### Configuration (Optional Enhancement)
- [ ] Consider optional flag to toggle timestamp display (e.g., `--log-timestamps`)
- [ ] Consider environment variable for log format customization
- [ ] Document configuration options if implemented

## Technical Considerations

### Implementation Approach

#### Option 1: Bash Built-in (Recommended)
```bash
log_message() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
    echo "[${timestamp}] [${level}] [${component}] ${message}"
}
```

**Pros**: Simple, no dependencies  
**Cons**: `date` command spawns process (minor overhead)

#### Option 2: EPOCHSECONDS (Bash 5+)
```bash
log_message() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date -d "@${EPOCHSECONDS}" -u +"%Y-%m-%dT%H:%M:%S")
    echo "[${timestamp}] [${level}] [${component}] ${message}"
}
```

**Pros**: Faster than spawning date process  
**Cons**: Requires Bash 5+ (check platform compatibility)

#### Option 3: Pre-cached Timestamp
```bash
# Cache timestamp at script start, update periodically
CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
```

**Pros**: Minimal overhead  
**Cons**: Not accurate for long-running operations

### Component Identification Strategy

Map script context to component names:
- `MAIN`: Main script logic
- `PARSER`: Argument parsing
- `SCANNER`: File scanning operations
- `PLUGIN`: Plugin execution
- `REPORT`: Report generation
- `UTIL`: Utility functions

### Timestamp Format Options
- **ISO 8601**: `2026-02-08T14:30:45Z` (recommended - standard)
- **RFC 3339**: `2026-02-08T14:30:45+00:00` (includes timezone)
- **Unix epoch**: `1739023845` (machine-readable)
- **Custom**: `2026-02-08 14:30:45` (human-readable)

**Recommendation**: ISO 8601 for standardization and tooling compatibility

### Files to Modify
- `scripts/doc.doc.sh`: Update logging functions
  - `log_debug()`
  - `log_info()`
  - `log_error()`
- Update calls to logging functions throughout script
- `tests/unit/test_verbose_logging.sh`: Update test expectations
- `03_documentation/01_architecture/08_concepts/08_0003_cli_interface_concept.md`: Mark as implemented

## Testing Requirements

### Unit Tests
- [ ] Test timestamp format correctness (ISO 8601 compliance)
- [ ] Test component identification for all contexts
- [ ] Test all log levels produce correct format
- [ ] Test log message content preservation (special characters, quotes)
- [ ] Test performance impact (benchmark timestamp generation)

### Integration Tests
- [ ] Test logging during file scanning operations
- [ ] Test logging during plugin execution
- [ ] Test logging during report generation
- [ ] Test logging in verbose vs. non-verbose modes

### Regression Tests
- [ ] Verify existing tests still pass with new format
- [ ] Verify backward compatibility with log consumers
- [ ] Verify no breaking changes to script behavior

## Documentation Requirements
- [ ] Update help text with example log format
- [ ] Update architecture documentation (mark deviation as resolved)
- [ ] Update user documentation with logging format details
- [ ] Document configuration options if implemented
- [ ] Add examples to README showing log output

## Risks and Mitigation

### Risk 1: Performance Impact
- **Description**: Date command spawning may slow down high-volume logging
- **Likelihood**: Low
- **Impact**: Low
- **Mitigation**: Benchmark and optimize if needed; consider caching strategies

### Risk 2: Platform Compatibility
- **Description**: Date command format flags vary across platforms
- **Likelihood**: Medium (macOS uses BSD date)
- **Impact**: Medium
- **Mitigation**: Test on all supported platforms; use portable date formats

### Risk 3: Breaking Changes
- **Description**: Log format change may break downstream tools
- **Likelihood**: Low
- **Impact**: Low
- **Mitigation**: Update tests first; maintain backward compatibility options

## Dependencies
- Platform detection already implemented (feature_0001)
- Verbose logging mode already implemented (feature_0001)
- No external tool dependencies required

## Effort Estimate
- **Size**: Small
- **Complexity**: Low
- **Estimated Effort**: 2-4 hours
  - Implementation: 1-2 hours
  - Testing: 1 hour
  - Documentation: 1 hour

## Future Enhancements
- Structured logging (JSON format) for machine parsing
- Log level filtering at runtime
- Log rotation for long-running operations
- Configurable log destinations (file, syslog, stdout)
- Color-coded log levels for terminal output

## Related Work
- Architecture Sync Report (2026-02-08): Identified logging format deviation
- ADR-0006 (if created): Decision to enhance logging format
- Feature 0001: Basic Script Structure (provides logging foundation)

## Notes
This feature resolves the architecture deviation identified during the 2026-02-08 architecture synchronization. While the current simplified logging was deemed acceptable for v1.0, adding timestamps will improve the tool's production readiness and align with the original architecture vision.

The enhancement should be implemented before the tool processes large numbers of files, as timestamp correlation becomes more valuable with higher log volume.
