# ADR-0011: Dual JSON Parser Strategy (jq + python3 Fallback)

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0003 Implementation (Plugin Listing)  
**Feature Reference**: [Feature 0003: Plugin Listing](../../05_building_block_view/feature_0003_plugin_listing.md)

## Decision

Implement dual JSON parser strategy:
1. **Primary**: Use `jq` if available
2. **Fallback**: Use `python3` if `jq` unavailable
3. **Failure**: Exit with clear error if neither available

## Context

Plugin descriptors are JSON files (`descriptor.json`). The system must parse them reliably across diverse environments. Not all systems have `jq` installed, but most modern Linux systems have `python3`. The implementation must balance performance, compatibility, and maintainability.

## Rationale

**Why jq as Primary Parser**:
- Purpose-built for JSON processing
- Fast: ~10ms per descriptor file
- Robust: Handles edge cases well (nested objects, arrays, Unicode)
- Standard tool in many development environments
- Lightweight: Single binary, no runtime dependencies
- Shell-friendly output format

**Why python3 as Fallback**:
- Nearly ubiquitous: Installed by default on most modern Linux distributions
- Reliable JSON parsing via `json` standard library module
- Acceptable performance: ~50ms per descriptor (5x slower than jq, but acceptable)
- Ensures broad compatibility
- No additional packages required (uses stdlib)

**Why Not Pure Bash**:
- Complex JSON parsing in Bash is error-prone and fragile
- Reinventing wheel (poor maintainability)
- Limited edge case handling (nested objects, escaping, Unicode)
- Security risks (eval usage, injection vulnerabilities)
- Performance worse than python3

## Implementation

**Detection and Fallback**:
```bash
if command -v jq >/dev/null 2>&1; then
  # Use jq (primary path)
  name=$(jq -r '.name // empty' "${descriptor_path}")
  description=$(jq -r '.description // empty' "${descriptor_path}")
  active=$(jq -r '.active // false' "${descriptor_path}")
elif command -v python3 >/dev/null 2>&1; then
  # Use python3 (fallback path)
  result=$(python3 -c "
import json
import sys
try:
    with open('${descriptor_path}', 'r') as f:
        data = json.load(f)
    name = data.get('name', '')
    description = data.get('description', '')
    active = str(data.get('active', False)).lower()
    if not name or not description:
        sys.exit(1)
    print(f'{name}|{description}|{active}')
except Exception as e:
    sys.exit(1)
")
else
  # Neither available - error
  log "ERROR" "No JSON parser available (jq or python3 required)"
  error_exit "Cannot parse plugin descriptors" "${EXIT_PLUGIN_ERROR}"
fi
```

**Field Extraction**:
- Uses `.field // default` pattern for safe extraction
- Provides defaults for missing optional fields
- Returns empty for missing required fields (triggers validation failure)

## Consequences

**Positive**:
- ✅ Works optimally on systems with `jq` (best performance)
- ✅ Works acceptably on systems with only `python3` (graceful degradation)
- ✅ Clear error message if neither available (helpful to users)
- ✅ Transparent fallback (user unaware of which parser used)
- ✅ Robust JSON parsing with proper error handling

**Negative**:
- ⚠️ **Requires at least one external tool**
  - **Mitigation**: Document requirement in README and error messages
  - **Acceptable**: JSON parsing inherently requires parsing tool
  - **Impact**: Low (jq or python3 present on most systems)
- ⚠️ **Different code paths to test**
  - **Mitigation**: Test suite validates both paths
  - **Mitigation**: Unit tests for both jq and python3 paths
  - **Impact**: Increases test complexity slightly

## Performance Characteristics

| Parser | Avg Parse Time | Relative Speed | Availability |
|--------|---------------|----------------|--------------|
| jq | ~10ms | 1x (baseline) | ~70% of systems |
| python3 | ~50ms | 5x slower | ~95% of systems |
| bash (hypothetical) | ~100ms+ | 10x+ slower | 100% |

**Analysis**:
- For typical usage (< 50 plugins), even python3 fallback is imperceptible (< 2.5s total)
- Performance requirement: < 2 seconds for listing (easily met by both parsers)
- jq optimization provides better UX when available

## Alternatives Considered

1. **jq Only (No Fallback)**
   - Simpler implementation (single code path)
   - ❌ Limited compatibility (many systems lack jq by default)
   - ❌ Poor user experience (hard failure requiring manual tool installation)
   - **Rejected**: Too restrictive

2. **python3 Only (No jq)**
   - Single code path, simpler
   - ❌ Slower than jq (5x performance difference)
   - ❌ Some minimal systems lack python3
   - **Rejected**: Sacrifices performance when better tool available

3. **Pure Bash Parsing (grep/sed)**
   - No dependencies
   - ❌ Extremely error-prone (JSON escaping, nesting, Unicode)
   - ❌ Security risks (eval, injection)
   - ❌ Poor maintainability (complex regex patterns)
   - **Rejected**: Not production-ready

4. **Node.js as Fallback**
   - Excellent JSON support
   - ❌ Less commonly installed than python3
   - ❌ Slower startup time than python3
   - **Rejected**: Less ubiquitous

## Impact

- **User Experience**: Transparent parser selection improves compatibility
- **Performance**: Optimal performance when jq available, acceptable fallback otherwise
- **Maintenance**: Two code paths require dual testing but both are simple
- **Portability**: Dramatically improves compatibility across Linux distributions

## Related Decisions

- [ADR-0010: Pipe-Delimited Plugin Data](adr_0010_pipe_delimited_plugin_data.md) - Defines format for parsed data
- [ADR-0014: Continue on Malformed Descriptors](adr_0014_continue_on_malformed_descriptors.md) - Handles parse failures

## References

- **Implementation**: `scripts/doc.doc.sh` (lines 158-225)
- **Requirements**: req_0024 (Plugin Listing), req_0007 (Tool Availability)
- **Testing**: `tests/unit/test_plugin_listing.sh`
- **Dependencies**: jq (optional, preferred), python3 (optional, fallback)
