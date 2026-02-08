# Architecture Decision Record: Plugin Listing Implementation

**ADR ID**: feature_0003_decisions  
**Date**: 2026-02-06  
**Status**: Accepted  
**Feature**: feature_0003 (Plugin Listing)  
**Requirements**: req_0024 (Plugin Listing), req_0022 (Plugin-based Extensibility)

## Context

The plugin listing feature (`-p list` command) required several architectural decisions regarding data formats, parsing strategies, precedence rules, and display formatting. These decisions impact system robustness, maintainability, and user experience.

---

## Decision 1: Pipe-Delimited Internal Data Format

### Status
**Accepted**

### Context
Plugin data must be passed between functions (`discover_plugins` → `list_plugins` → `display_plugin_list`). Options include JSON strings, structured objects, or delimited strings.

### Decision
Use pipe-delimited strings: `"name|description|active"`

### Rationale

**Advantages**:
- Bash-native: No external dependencies for parsing
- Efficient: Simple string manipulation with parameter expansion
- Lightweight: Minimal memory overhead
- Sufficient: Three fields easily separated by pipes

**Why Not JSON**:
- Requires `jq` or `python3` for every parse operation
- Overkill for simple three-field data
- Performance overhead for repeated parsing

**Why Pipe Delimiter**:
- Unlikely to appear in plugin names (restricted charset)
- Unlikely in descriptions (not standard punctuation)
- Clear visual separator
- Single character

### Consequences

**Positive**:
- ✅ Fast internal data exchange
- ✅ No external tool dependencies
- ✅ Simple to implement and debug

**Negative**:
- ⚠️ Breaks if descriptions contain pipe character
  - **Mitigation**: Validate descriptors, sanitize on parse
  - **Likelihood**: Low (pipes rare in descriptive text)
- ⚠️ Not human-readable format
  - **Mitigation**: Only internal format, never user-facing

### Alternatives Considered

1. **JSON Strings**
   - Would require parsing on every use
   - Heavyweight for simple data
   - External dependency

2. **Bash Arrays**
   - Would require global arrays or complex passing
   - Associative arrays not well-suited for list data
   - Harder to serialize for piping

3. **Colon-Delimited**
   - Conflicts with paths, URLs in descriptions
   - Less visually distinct than pipe

---

## Decision 2: Dual JSON Parser Strategy (jq + python3 Fallback)

### Status
**Accepted**

### Context
Plugin descriptors are JSON files. The system must parse them reliably across diverse environments. Not all systems have `jq` installed, but most have `python3`.

### Decision
1. **Primary**: Use `jq` if available (check with `command -v jq`)
2. **Fallback**: Use `python3` if `jq` unavailable
3. **Failure**: Exit with error if neither available

### Rationale

**Why jq as Primary**:
- Purpose-built for JSON processing
- Fast: ~10ms per descriptor
- Robust: Handles edge cases well
- Standard tool in many environments

**Why python3 as Fallback**:
- Nearly ubiquitous (installed by default on most Linux)
- Reliable JSON parsing (`json` standard library)
- Acceptable performance: ~50ms per descriptor
- Ensures broad compatibility

**Why Not Pure Bash**:
- Complex JSON parsing in Bash is error-prone
- Reinventing wheel (poor maintainability)
- Limited edge case handling
- Security risks (eval, injection)

### Implementation

**jq Path**:
```bash
name=$(jq -r '.name // empty' "${descriptor_path}")
description=$(jq -r '.description // empty' "${descriptor_path}")
active=$(jq -r '.active // false' "${descriptor_path}")
```

**python3 Path**:
```python
import json
with open('${descriptor_path}', 'r') as f:
    data = json.load(f)
name = data.get('name', '')
description = data.get('description', '')
active = str(data.get('active', False)).lower()
```

### Consequences

**Positive**:
- ✅ Works on systems with `jq` (optimal performance)
- ✅ Works on systems with only `python3` (graceful degradation)
- ✅ Clear error message if neither available
- ✅ Transparent fallback (user unaware)

**Negative**:
- ⚠️ Requires at least one external tool
  - **Mitigation**: Document requirement, provide clear error
  - **Acceptable**: JSON parsing requires some tool
- ⚠️ Different code paths to test
  - **Mitigation**: Test both paths, unit tests

### Alternatives Considered

1. **jq Only (No Fallback)**
   - Simpler implementation
   - ❌ Limited compatibility (many systems lack jq)
   - ❌ Poor user experience (hard failure on missing tool)

2. **python3 Only**
   - Single code path
   - ❌ Slower than jq
   - ❌ Some minimal systems lack python3

3. **Pure Bash Parsing**
   - No dependencies
   - ❌ Error-prone, complex
   - ❌ Security risks
   - ❌ Poor maintainability

---

## Decision 3: Platform-Specific Plugin Precedence

### Status
**Accepted**

### Context
Plugins can exist in both platform-specific directories (`plugins/ubuntu/`) and cross-platform directories (`plugins/all/`). When the same plugin name exists in both, the system must choose which to use.

### Decision
**Platform-specific plugins take precedence** over cross-platform plugins with the same name.

### Rationale

**Use Cases**:
1. **Platform Optimization**: Ubuntu-specific `stat` plugin using Ubuntu-specific flags
2. **Tool Availability**: Platform-specific plugin uses tools available on that platform
3. **Customization**: User overrides generic plugin with platform-optimized version
4. **Migration Path**: Plugin evolves from generic → platform-specific

**Precedence Logic**:
```
plugins/ubuntu/example → Added first, marked as "seen"
plugins/all/example    → Skipped (duplicate detected)
Result: Only Ubuntu version used
```

**Discovery Order**:
1. Scan platform directory first
2. Add plugins to `seen_plugins` hash
3. Scan cross-platform directory
4. Skip plugins already in `seen_plugins`

### Consequences

**Positive**:
- ✅ Enables platform optimizations
- ✅ Allows user customization without forking
- ✅ Clear, predictable behavior
- ✅ Supports plugin evolution path

**Negative**:
- ⚠️ Cross-platform version silently ignored
  - **Mitigation**: Log at DEBUG level in verbose mode
  - **Acceptable**: Intentional override behavior
- ⚠️ Must document precedence rules
  - **Mitigation**: Document in plugin concept, help text

### Alternatives Considered

1. **Error on Duplicate**
   - ❌ Prevents legitimate use cases (optimization, customization)
   - ❌ User must manually manage conflicts

2. **Cross-Platform Precedence**
   - ❌ Backwards: Platform-specific should override generic
   - ❌ Counter-intuitive

3. **Load Both and Warn**
   - ❌ Which one to use during execution?
   - ❌ Ambiguity undesirable

4. **User Configuration**
   - ❌ Too complex for simple use case
   - ❌ Adds configuration file requirement

---

## Decision 4: Description Truncation at 80 Characters

### Status
**Accepted**

### Context
Plugin descriptions can be arbitrarily long. Listing must display descriptions in a terminal-friendly format without excessive wrapping or scrolling.

### Decision
Truncate descriptions exceeding 80 characters to 77 characters + "..." ellipsis.

### Rationale

**80-Character Limit**:
- Standard terminal width (historical convention)
- Many terminals default to 80 columns
- Prevents horizontal scrolling
- Maintains visual consistency

**77 + Ellipsis ("...")**:
- 77 characters of text
- 3 characters for ellipsis
- Total: 80 characters
- Clear indicator of truncation

**Implementation**:
```bash
if [[ ${#description} -gt 80 ]]; then
  description="${description:0:77}..."
fi
```

### Consequences

**Positive**:
- ✅ Consistent, readable output
- ✅ No terminal wrapping on standard terminals
- ✅ Maintains visual layout
- ✅ Quick overview (detailed info in descriptor file)

**Negative**:
- ⚠️ Information loss in listing
  - **Mitigation**: Full description available via descriptor file or `-p info` (future)
  - **Acceptable**: Listing is overview, not full documentation
- ⚠️ Some 120+ column terminal users lose space
  - **Acceptable**: 80-column standard is broad compatibility

### Alternatives Considered

1. **No Truncation**
   - ❌ Inconsistent visual appearance
   - ❌ Wrapping on standard terminals
   - ❌ Harder to scan list

2. **Dynamic Width (Terminal Detection)**
   - ❌ Complex: Requires terminal capability detection
   - ❌ Inconsistent: Different outputs on different terminals
   - ❌ Overkill for simple listing

3. **Different Truncation Length**
   - 60 chars: ❌ Too short, loses too much information
   - 100 chars: ❌ Wraps on standard terminals
   - 120 chars: ❌ Only works on wide terminals

---

## Decision 5: Continue on Malformed Descriptors

### Status
**Accepted**

### Context
During plugin discovery, the system may encounter malformed or invalid plugin descriptors (missing required fields, invalid JSON, etc.). The system must decide whether to fail entirely or continue with other plugins.

### Decision
**Log warning and skip malformed plugins**, continue processing remaining plugins.

### Rationale

**Plugin Listing as Discovery Tool**:
- Users use `-p list` to see what's available
- One bad plugin shouldn't hide all others
- Helpful to see partial list + what failed

**Debugging Benefits**:
- User can identify problematic plugin from warning
- Other valid plugins still functional
- Encourages fixing rather than hiding issues

**Unix Philosophy**:
- "Be liberal in what you accept"
- Robustness principle
- Fail gracefully, not catastrophically

### Implementation

**Error Handling Flow**:
```
parse_plugin_descriptor() fails
  → log("WARN", "Plugin descriptor missing 'name' field: ...")
  → return 1

discover_plugins() receives failure
  → Skip adding to plugin_list[]
  → Continue with next descriptor
  → No fatal error
```

**Validation Rules**:
- Missing `name` field → Skip with warning
- Missing `description` field → Skip with warning
- Malformed JSON → Skip with warning
- File not readable → Skip with warning

### Consequences

**Positive**:
- ✅ Robust: One failure doesn't break entire system
- ✅ Helpful: User sees what works and what doesn't
- ✅ Debuggable: Warnings identify problematic plugins
- ✅ Flexible: Tolerates user errors

**Negative**:
- ⚠️ Silent failure (without verbose mode)
  - **Mitigation**: WARN level always shown
  - **Impact**: Low - user sees warning
- ⚠️ Incomplete plugin list
  - **Acceptable**: Better than no list at all
  - **Mitigation**: Clear warning messages

### Alternatives Considered

1. **Fail Fast (Exit on First Error)**
   - ❌ Too brittle for extensible system
   - ❌ One bad plugin breaks everything
   - ❌ Poor user experience

2. **Fail Silent (No Warning)**
   - ❌ User doesn't know plugin failed
   - ❌ Harder to debug
   - ❌ Violates principle of least surprise

3. **Collect Errors, Report at End**
   - ✅ Shows all problems at once
   - ❌ More complex implementation
   - ⏳ Potential future enhancement

---

## Decision 6: Alphabetical Sorting by Plugin Name

### Status
**Accepted**

### Context
Plugin list may contain plugins from different directories in discovery order. Display order affects usability and predictability.

### Decision
Sort plugins alphabetically by name before display.

### Rationale

**Usability**:
- Predictable: Same order every time
- Scannable: Easy to find specific plugin
- Professional: Organized presentation

**Implementation**:
```bash
IFS=$'\n' sorted_plugins=($(sort <<<"${plugins[*]}"))
```

**Case Sensitivity**:
- Uses default `sort` behavior (case-sensitive)
- Uppercase sorts before lowercase
- Acceptable: Plugin names typically lowercase

### Consequences

**Positive**:
- ✅ Consistent output across runs
- ✅ Easy to scan and find plugins
- ✅ Professional appearance

**Negative**:
- ⚠️ Case-sensitive sorting
  - Impact: Uppercase names appear first
  - Acceptable: Plugin naming convention is lowercase

### Alternatives Considered

1. **Discovery Order (No Sorting)**
   - ❌ Unpredictable (filesystem order)
   - ❌ Platform-specific then cross-platform grouping may confuse

2. **Case-Insensitive Sorting**
   - Would require `sort -f`
   - Minimal benefit (plugins typically lowercase)
   - Current approach sufficient

3. **Group by Status (Active/Inactive)**
   - ❌ Less intuitive than alphabetical
   - ❌ Harder to find specific plugin
   - Could be future enhancement (with flag)

---

## Summary of Decisions

| Decision | Status | Impact | Rationale |
|----------|--------|--------|-----------|
| Pipe-Delimited Format | ✅ Accepted | Internal data exchange | Bash-native, efficient |
| Dual Parser Strategy | ✅ Accepted | JSON parsing | Optimal + fallback = robust |
| Platform Precedence | ✅ Accepted | Plugin selection | Enables optimization |
| 80-Char Truncation | ✅ Accepted | Display formatting | Terminal compatibility |
| Continue on Error | ✅ Accepted | Error handling | Robust, helpful |
| Alphabetical Sorting | ✅ Accepted | Display order | Predictable, scannable |

---

## Compliance with Vision

All decisions align with architecture vision principles:

- **Simplicity**: ✅ Bash-native solutions where possible
- **Robustness**: ✅ Fallback strategies, graceful error handling
- **Unix Philosophy**: ✅ Do one thing well, composable
- **Extensibility**: ✅ Platform-specific override mechanism
- **Usability**: ✅ Clear output, helpful errors

---

## Future Considerations

**Potential Enhancements** (not breaking changes):

1. **Case-Insensitive Sorting** (`sort -f`)
2. **Error Summary** (collect and report all errors at end)
3. **Configurable Truncation** (environment variable for width)
4. **Group by Status** (optional flag for `--group-by-status`)
5. **Full Description Display** (`-p info <name>` command)

These enhancements would build on existing decisions without requiring architectural changes.

---

## References

- **Vision**: `01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md`
- **Requirements**: 
  - `req_0024`: Plugin Listing
  - `req_0022`: Plugin-based Extensibility
- **Implementation**: `scripts/doc.doc.sh` (lines 158-370)
- **Documentation**:
  - Building Blocks: `03_documentation/01_architecture/05_building_block_view/feature_0003_plugin_listing.md`
  - Runtime View: `03_documentation/01_architecture/06_runtime_view/feature_0003_plugin_listing.md`
