# IDR-0007: Continue on Malformed Plugin Descriptors

**ID**: IDR-0007  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0003: Data-Driven Plugin Orchestration](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0003_data_driven_plugin_orchestration.md)

## Decision

Log warnings and skip malformed plugins during discovery, continuing to process remaining valid plugins rather than failing entirely.

## Context

During plugin discovery, the system may encounter various types of descriptor errors:
- Missing required fields (`name`, `description`)
- Invalid JSON syntax
- File permission issues
- Corrupted files

The system must decide whether to fail entirely on first error or continue processing remaining plugins.

## Rationale

**Plugin Listing as Discovery Tool**:
- Primary purpose: Help users discover **available** plugins
- One malformed plugin shouldn't hide all other functional plugins
- Partial list with errors is more helpful than no list at all
- Users can investigate and fix problematic plugins while using others

**Debugging Benefits**:
- Warning messages identify which plugin failed and why
- User can fix problematic plugin without losing access to others
- Encourages fixing issues rather than hiding them
- Verbose mode provides detailed diagnostics

**Unix Philosophy - Robustness Principle**:
- "Be liberal in what you accept, conservative in what you send"
- Fail gracefully rather than catastrophically
- Provide useful output even in degraded conditions
- Tools should be resilient to imperfect input

**Real-World Plugin Development**:
- Developers iterate on plugin descriptors
- Temporary syntax errors during development shouldn't break entire system
- Allows testing valid plugins while fixing broken ones

## Implementation

**Error Handling Flow**:
```bash
parse_plugin_descriptor() {
  # Validation checks
  if [[ -z "${name}" ]]; then
    log "WARN" "Plugin descriptor missing 'name' field: ${descriptor_path}"
    return 1  # Signal failure, don't add to list
  fi
  
  if [[ -z "${description}" ]]; then
    log "WARN" "Plugin descriptor missing 'description' field: ${descriptor_path}"
    return 1
  fi
  
  # Success: return parsed data
  echo "${name}|${description}|${active}"
  return 0
}

discover_plugins() {
  while IFS= read -r -d '' descriptor_file; do
    local plugin_data
    if plugin_data=$(parse_plugin_descriptor "${descriptor_file}"); then
      # Success: add to list
      plugin_list+=("${plugin_data}")
    fi
    # Failure: Warning already logged, continue with next plugin
  done
}
```

**Validation Rules** (Skip on Failure):
- Missing `name` field → Log warning, skip plugin
- Missing `description` field → Log warning, skip plugin
- Malformed JSON → Log warning, skip plugin
- File not readable → Log warning, skip plugin
- Parser failure (jq/python3 error) → Log warning, skip plugin

**Logging Levels**:
- `WARN`: Always shown (even without verbose)
- Includes file path for easy identification
- Describes specific problem clearly

## Reason

Error handling strategy necessary during Feature 0003 implementation to specify behavior when encountering malformed plugin descriptors. Vision (ADR-0003) emphasizes extensibility but does not specify error handling for malformed plugins. Decision prioritizes robustness and user experience over strict validation.

## Deviation from Vision

No deviation - this decision fills implementation details not specified in vision. ADR-0003 (Data-Driven Plugin Orchestration) focuses on orchestration strategy but does not mandate error handling behavior. This implementation follows Unix robustness principles and aligns with extensibility goals.

## Associated Risks

No associated risks - decision aligns with robustness principles. Primary considerations are well-mitigated:
- Incomplete plugin list: User explicitly warned via WARN-level messages
- Potential to mask systemic issues: Each failure logged separately (not silently ignored)
- Better graceful degradation than catastrophic failure
- Supports iterative plugin development

## Consequences

**Positive**:
- ✅ **Robust**: One plugin failure doesn't break entire system
- ✅ **Helpful**: User sees what works and what doesn't
- ✅ **Debuggable**: Warnings identify problematic plugins clearly
- ✅ **Flexible**: Tolerates user errors during development
- ✅ **Graceful Degradation**: Partial functionality maintained

**Negative**:
- ⚠️ **Incomplete plugin list if errors exist**
  - **Mitigation**: WARN level messages always shown (not just in verbose)
  - **Mitigation**: Clear indication of what failed and why
  - **Acceptable**: Better than no list at all
  - **Impact**: User aware of problems from warnings

- ⚠️ **Could mask systemic issues**
  - **Mitigation**: Each failure logged separately (not silently ignored)
  - **Mitigation**: User should notice repeated failures
  - **Acceptable**: Individual plugin failures expected during development

## Error Examples

**Example 1: Missing Required Field**
```bash
$ ./scripts/doc.doc.sh -p list
[WARN] Plugin descriptor missing 'name' field: /path/to/plugins/broken/descriptor.json
Available Plugins:
====================================

[ACTIVE]   stat
           Retrieves file statistics...
```

**Example 2: Malformed JSON**
```bash
$ ./scripts/doc.doc.sh -v -p list
[INFO] Listing available plugins
[DEBUG] Searching for plugins in: /path/to/plugins
[DEBUG] Found descriptor: /path/to/plugins/broken/descriptor.json
[DEBUG] Parsing descriptor: /path/to/plugins/broken/descriptor.json
[WARN] Plugin descriptor missing 'description' field: /path/to/plugins/broken/descriptor.json
[DEBUG] Found descriptor: /path/to/plugins/stat/descriptor.json
[DEBUG] Parsing descriptor: /path/to/plugins/stat/descriptor.json
[DEBUG] Added platform plugin: stat
Available Plugins:
====================================

[ACTIVE]   stat
           Retrieves file statistics...
```

## Alternatives Considered

1. **Fail Fast (Exit on First Error)**
   - ❌ Too brittle for extensible plugin system
   - ❌ One malformed plugin breaks entire listing
   - ❌ Poor developer experience
   - ❌ Hides all functional plugins
   - **Rejected**: Not production-ready

2. **Fail Silent (No Warning)**
   - ❌ User doesn't know plugin failed
   - ❌ Harder to debug issues
   - ❌ Violates principle of least surprise
   - ❌ Incomplete list without explanation
   - **Rejected**: Unhelpful to users

3. **Collect All Errors, Report Summary at End**
   - ✅ Shows all problems together
   - ❌ More complex implementation
   - ❌ Delays error feedback
   - ⏳ Potential future enhancement
   - **Deferred**: Can add later without breaking change

4. **Require All Plugins Valid (Validation Phase)**
   - Pre-validate all descriptors before listing any
   - ❌ All-or-nothing approach too restrictive
   - ❌ Poor developer experience
   - ❌ Doesn't align with discovery tool purpose
   - **Rejected**: Too strict

## Impact

- **Robustness**: System resilient to individual plugin failures
- **Usability**: Helpful partial results better than no results
- **Developer Experience**: Supports iterative plugin development
- **Debugging**: Clear error messages aid problem identification

## Testing

Test cases verify correct behavior:
- Valid plugin + malformed plugin → Lists valid plugin, warns about malformed
- All malformed plugins → Shows "No plugins found" with warnings
- No plugins directory → Appropriate error message
- Mix of valid/invalid → All valid plugins shown

## Related Decisions

- [ADR-0011: Dual JSON Parser](adr_0011_dual_json_parser.md) - Parser failure handling
- [ADR-0004: Log Level Design](adr_0004_log_level_design.md) - Defines WARN level behavior

## References

- **Implementation**: `scripts/doc.doc.sh` (lines 165-175, 242-290)
- **Requirements**: req_0024 (Plugin Listing)
- **Testing**: `tests/unit/test_plugin_listing.sh`
- **Error Codes**: Uses return codes, not exit codes (continue processing)
