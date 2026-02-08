# IDR-0003: Pipe-Delimited Internal Data Format for Plugin Data

**ID**: IDR-0003  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08  
**Related ADRs**: [ADR-0003: Data-Driven Plugin Orchestration](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0003_data_driven_plugin_orchestration.md)

## Decision

Use pipe-delimited strings (`"name|description|active"`) for internal plugin data exchange between functions.

## Context

Plugin data must be passed between functions (`discover_plugins` → `list_plugins` → `display_plugin_list`). The implementation requires an efficient, Bash-native format for passing plugin metadata (name, description, active status) through the function call chain.

## Rationale

**Advantages of Pipe-Delimited Format**:
- **Bash-native**: No external dependencies for parsing
- **Efficient**: Simple string manipulation with parameter expansion (`${var%%|*}`, `${var##*|}`)
- **Lightweight**: Minimal memory overhead compared to structured formats
- **Sufficient**: Three fields easily separated by single-character delimiter
- **Performance**: Fast string operations, no subprocess overhead

**Why Not JSON**:
- Requires `jq` or `python3` for every parse operation
- Overkill for simple three-field data structure
- Performance overhead for repeated parsing in loops
- Adds complexity for internal data passing

**Why Pipe Character**:
- Unlikely to appear in plugin names (plugin names use restricted charset)
- Rare in descriptions (not standard punctuation)
- Clear visual separator in debugging
- Single character (efficient)

## Implementation

**Data Format**:
```bash
"plugin-name|Plugin description text|true"
```

**Parsing Example**:
```bash
local name="${plugin_data%%|*}"           # Extract name
local rest="${plugin_data#*|}"            # Remove name, get rest
local description="${rest%%|*}"           # Extract description
local active="${rest##*|}"                # Extract active
```

**Construction**:
```bash
echo "${name}|${description}|${active}"
```

## Reason

Pipe-delimited format chosen for internal data exchange to avoid external tool dependencies during data passing between functions. This implementation detail optimizes for performance and Bash-native operations while the vision (ADR-0003) focuses on plugin orchestration strategy without specifying internal data format.

## Deviation from Vision

No deviation - this decision fills implementation details not specified in vision. ADR-0003 (Data-Driven Plugin Orchestration) describes the orchestration strategy but does not mandate internal data format. The pipe-delimited approach complements the vision by providing efficient Bash-native data exchange.

## Associated Risks

No associated risks - decision aligns with vision principles. The primary risk (pipe character in descriptions) is mitigated through descriptor validation and is low impact. Trade-off between format simplicity and robustness is acceptable for internal data exchange.

## Consequences

**Positive**:
- ✅ Fast internal data exchange (no external tools)
- ✅ No external tool dependencies for data passing
- ✅ Simple to implement and debug
- ✅ Predictable performance characteristics

**Negative**:
- ⚠️ **Breaks if descriptions contain pipe character**
  - **Mitigation**: Validate descriptors during parsing
  - **Mitigation**: Sanitize pipe characters in descriptions if present
  - **Likelihood**: Low (pipes rare in descriptive text)
  - **Impact**: Limited to malformed descriptors
- ⚠️ **Not human-readable format**
  - **Mitigation**: Only internal format, never user-facing
  - **Mitigation**: JSON descriptors remain human-readable
  - **Impact**: No user-facing impact

## Alternatives Considered

1. **JSON Strings**
   - Would require parsing on every function use
   - Heavyweight for simple data
   - External dependency (jq/python3)
   - **Rejected**: Over-engineered for internal data

2. **Bash Associative Arrays**
   - Would require global arrays or complex passing mechanisms
   - Difficult to serialize for piping/subprocess
   - Not well-suited for list data structures
   - **Rejected**: Increased complexity

3. **Colon-Delimited (`:` separator)**
   - Conflicts with paths, URLs in descriptions
   - Less visually distinct than pipe
   - **Rejected**: Higher collision risk

4. **Tab-Delimited**
   - More prone to formatting issues
   - Less visible in debugging
   - **Rejected**: Pipe is clearer

## Impact

- **Functions Affected**: `discover_plugins()`, `list_plugins()`, `display_plugin_list()`
- **Performance**: Negligible overhead for data format operations
- **Maintainability**: Simple format easy to understand and modify
- **Future Compatibility**: Format can accommodate additional fields if needed (e.g., `name|description|active|version`)

## Related Decisions

- [ADR-0011: Dual JSON Parser Strategy](adr_0011_dual_json_parser.md) - Handles parsing of plugin descriptor files
- [ADR-0014: Continue on Malformed Descriptors](adr_0014_continue_on_malformed_descriptors.md) - Error handling for malformed data

## References

- **Implementation**: `scripts/doc.doc.sh` (lines 158-290, 359-370)
- **Requirements**: req_0024 (Plugin Listing)
- **Testing**: `tests/unit/test_plugin_listing.sh`
