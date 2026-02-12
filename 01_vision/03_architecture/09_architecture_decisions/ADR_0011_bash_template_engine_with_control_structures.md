# ADR-0011: Bash Template Engine with Control Structures

**ID**: ADR-0011  
**Status**: Accepted  
**Created**: 2026-02-12  
**Last Updated**: 2026-02-12  
**Supersedes**: [ADR-0005](ADR_0005_template_based_report_generation.md) (Simple Variable Substitution)

## Context

[ADR-0005](ADR_0005_template_based_report_generation.md) established template-based report generation using simple `{{variable}}` placeholder substitution. This decision was appropriate for the initial architecture but has proven insufficient for real-world reporting needs:

**Limitations of Simple Substitution** (from ADR-0005):
- Cannot conditionally include sections based on data availability
- Cannot iterate over arrays (tags, plugin results, file lists)
- Cannot provide template documentation via comments
- Results in awkward workarounds (empty sections, manual array formatting)

**Requirements Evolution**:
- [req_0040](../../../02_requirements/03_accepted/req_0040_template_engine_implementation.md) (ACCEPTED): Specifies template engine with conditionals, loops, comments
- [req_0034](../../../02_requirements/03_accepted/req_0034_template_variable_reference_documentation.md): Documents need for sophisticated template capabilities
- [Usability Quality Goal](../../01_introduction_and_goals/01_introduction_and_goals.md): "Non-programmer can create working template in < 30 minutes"

**User Feedback** (Hypothetical):
- Templates with empty sections for missing data look unprofessional
- Cannot iterate over plugin results arrays without custom scripting
- Cannot adapt report structure based on file type or analysis results
- Need inline comments to document template structure for team members

## Decision

Implement a **Mustache-like template engine in pure Bash** with the following capabilities:

### Template Syntax

**Variable Substitution** (retained from ADR-0005):
```markdown
{{variable_name}}
{{nested.field.name}}
```

**Conditionals** (NEW):
```markdown
{{#if variable}}
  Content shown only if variable is truthy (non-empty, non-zero)
{{else}}
  Optional else clause
{{/if}}
```

**Loops** (NEW):
```markdown
{{#each array}}
  {{this}}        - Current array element
  {{@index}}      - Zero-based iteration index
{{/each}}
```

**Comments** (NEW):
```markdown
{{! This is a template comment, removed from output}}
```

### Implementation Constraints

1. **Pure Bash**: No external template libraries (Jinja2, Mustache Ruby gem, etc.)
2. **Uses jq**: For JSON parsing and XPath-like access to workspace data
3. **Security First**: No code execution (no eval, command substitution, or dynamic scripting)
4. **Complexity Limits**: Maximum nesting depth, iteration counts to prevent DoS
5. **Graceful Degradation**: Malformed templates fail with clear error messages

## Rationale

### Why Full Template Engine vs. Simple Substitution?

**User Experience Requirements**:
- ✅ **Conditional Sections**: Show "No summary available" message instead of empty section
- ✅ **Array Iteration**: Display tags, plugin results, file lists without manual formatting
- ✅ **Template Documentation**: Comments explain template structure to non-programmers
- ✅ **Professional Output**: Reports adapt to data availability, no awkward empty sections

**Example: Simple Substitution Limitation**:
```markdown
## Tags
{{content.tags}}
```
**Problem**: If tags is empty array, output is literally "[]" or empty. Unprofessional.

**Example: Template Engine Solution**:
```markdown
{{#if content.tags}}
## Tags
{{#each content.tags}}
- {{this}}
{{/each}}
{{else}}
*No tags assigned*
{{/if}}
```
**Result**: Professional output regardless of data availability.

### Why Pure Bash Implementation?

| Alternative | Pro | Con | Decision |
|-------------|-----|-----|----------|
| **External Library** (Jinja2, Mustache) | Mature, feature-rich, tested | Requires Python/Ruby runtime, violates ADR-0001 | ❌ Rejected |
| **Embedded Scripting** (Lua in Bash) | Powerful templating | Complex integration, security risk (code execution) | ❌ Rejected |
| **Markdown Preprocessor** (m4, cpp) | Available on most systems | Not designed for templates, cryptic syntax | ❌ Rejected |
| **Pure Bash Engine** | No dependencies, full control, security | More implementation effort, less mature | ✅ **Accepted** |

**Key Advantages of Bash Implementation**:
- ✅ Aligns with ADR-0001 (Bash as primary language)
- ✅ No runtime dependencies beyond Bash + jq (already required)
- ✅ Full control over security boundaries (no external code execution)
- ✅ Complexity can be managed with careful design
- ✅ Portable across all target platforms without additional installation

### Why Mustache-like Syntax?

**Considered Syntaxes**:
- **Mustache** (`{{#if}}`, `{{#each}}`): Simple, widely known, no code execution by design
- **Jinja2-like** (`{% if %}`, `{% for %}`): More features, but invites code execution expectations
- **ERB-like** (`<% if %>`, `<% each %>`): Ugly in Markdown, looks like HTML/XML
- **Custom** (`$IF$`, `$EACH$`): Non-standard, learning curve for users

**Decision: Mustache-like** because:
- ✅ Simple, intuitive syntax (`{{...}}` clearly marks template directives)
- ✅ Widely known (Mustache used by Hugo, Handlebars, etc.)
- ✅ **Deliberately limited** - Mustache philosophy: logic-less templates (no arbitrary expressions)
- ✅ Reads well in Markdown (doesn't conflict with Markdown syntax)
- ✅ Design prevents code execution by default (no `{{eval(...)}}` or similar)

## Consequences

### Positive

✅ **Enhanced User Experience**: Templates can adapt to data availability  
✅ **Professional Output**: No awkward empty sections or unhelpful messages  
✅ **Maintainable Templates**: Comments document template structure inline  
✅ **No New Dependencies**: Pure Bash + jq (already required)  
✅ **Security Controlled**: No code execution by design  
✅ **Aligns with Requirements**: Implements req_0040, supports req_0034  

### Negative

⚠️ **Implementation Complexity**: More complex than simple string substitution  
⚠️ **Security Surface**: Conditionals and loops require careful input validation  
⚠️ **Performance Overhead**: Parsing and evaluating templates slower than substitution  
⚠️ **Maintenance Burden**: Custom implementation requires ongoing maintenance  
⚠️ **Feature Parity**: Will not have all features of mature template engines  

### Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Template Injection** (Code Execution) | HIGH | No eval/exec, sanitize variables, static parsing only (req_0049) |
| **Complexity DoS** (Infinite loops) | MEDIUM | Iteration limits (10,000), nesting depth limits (5), timeouts (30s) |
| **Parsing Errors** (Malformed templates) | LOW | Syntax validation before processing, clear error messages with line numbers |
| **Maintainability** (Custom code) | MEDIUM | Comprehensive test suite, inline documentation, modular design |

**Mitigation Details** (from req_0049):
- No `eval`, `exec`, or command substitution in template processing code
- Variable values sanitized (escape shell metacharacters: `;`, `|`, `&`, `$`, backticks)
- Maximum 10,000 total iterations per template
- Maximum 5 nesting levels for conditionals and loops
- 30-second processing timeout enforced
- Template syntax validation before execution
- Failed templates trigger error, do not produce partial output

### Trade-offs Accepted

**Complexity vs. Usability**: We accept increased implementation complexity to deliver significantly better user experience.

**Performance vs. Functionality**: We accept slower template processing (still < 1 second per file) to enable conditionals and loops.

**Custom Implementation vs. External Library**: We accept maintenance burden to preserve dependency-free architecture (ADR-0001).

**Security vs. Flexibility**: We deliberately limit template capabilities (no arbitrary expressions, no function definitions) to prevent code execution.

## Implementation Notes

### Architecture Integration

**Component**: `scripts/components/orchestration/template_engine.sh`  
**Layer**: Orchestration (consumed by Report Generator)  
**Dependencies**: 
- Core: Logging component
- External: `jq` for JSON parsing
- Security: Input validation component

**Interface**:
```bash
process_template <template_file> <workspace_json> [--timeout <seconds>]
  Returns: Generated markdown output (stdout)
  Exit Code: 0 (success), 1 (syntax error), 2 (timeout), 3 (security violation)
```

### Security Controls (per req_0049)

**Defense-in-Depth Layers**:
1. **Input Validation**: Template syntax validated before processing (balanced tags, allowed constructs only)
2. **Parsing Safety**: State machine parser, no dynamic code evaluation
3. **Variable Sanitization**: Escape shell and Markdown metacharacters in all substitutions
4. **Iteration Limits**: Counter enforced for loops, abort if exceeded
5. **Nesting Limits**: Stack depth tracked for conditionals/loops, abort if exceeded
6. **Timeout Enforcement**: Wrapper aborts processing after timeout
7. **Error Handling**: Malformed templates fail closed (no output), not open (partial output)

**Forbidden Operations**:
- ❌ No `eval "$template_code"`
- ❌ No `$(...command...)` or backticks in template processing
- ❌ No dynamic variable names: `${!variable_name}`
- ❌ No access to shell environment from templates
- ❌ No file system access from templates (template is just a string)
- ❌ No network access from templates

**Allowed Operations**:
- ✅ String comparison for conditionals (truthy/falsy check)
- ✅ Array iteration with index tracking
- ✅ JSON path resolution via jq (read-only)
- ✅ Built-in helper functions (format_date, human_readable_size) - safe, no user input

### Parsing Strategy

**State Machine Approach**:
```bash
# Simplified conceptual implementation
process_template() {
  local template="$1"
  local data="$2"
  local output=""
  local state="TEXT"  # States: TEXT, IN_CONDITIONAL, IN_LOOP
  local conditional_stack=()
  local loop_stack=()
  
  while read -r line; do
    case "$state" in
      TEXT)
        if [[ "$line" =~ \{\{#if ]]; then
          # Enter conditional
          state="IN_CONDITIONAL"
          conditional_stack+=("...")
        elif [[ "$line" =~ \{\{#each ]]; then
          # Enter loop
          state="IN_LOOP"
          loop_stack+=("...")
        elif [[ "$line" =~ \{\{([^}]+)\}\} ]]; then
          # Variable substitution
          local var="${BASH_REMATCH[1]}"
          local value=$(jq -r ".$var" <<< "$data")
          output+="${line/\{\{$var\}\}/$value}"
        else
          output+="$line"
        fi
        ;;
      # ... handle IN_CONDITIONAL and IN_LOOP states ...
    esac
  done <<< "$template"
  
  echo "$output"
}
```

**Note**: Actual implementation more sophisticated (nested conditionals, loop contexts, error handling).

### Testing Requirements

**Unit Tests** (feature_0008 DoD):
- Variable substitution (simple, nested, missing, special characters)
- Conditionals (truthy, falsy, else clause, nested)
- Loops (non-empty arrays, empty arrays, nested loops, @index)
- Comments (inline, block, multiline)
- Syntax validation (unbalanced tags, malformed syntax)
- Security (injection attempts, DoS attempts)

**Integration Tests**:
- Complete template processing with real workspace JSON
- Error handling for malformed templates
- Performance with large templates and data sets

**Security Tests (Critical)**:
- Template injection fuzzing (req_0049)
- Code execution attempts (eval, command substitution, backticks)
- Resource exhaustion (infinite loops, deep nesting, large variables)

## Related Items

- **Supersedes**: [ADR-0005](ADR_0005_template_based_report_generation.md) - Simple variable substitution
- **Implements**: [req_0040](../../../02_requirements/03_accepted/req_0040_template_engine_implementation.md) - Template Engine Implementation
- **Security**: [req_0049](../../../02_requirements/03_accepted/req_0049_template_injection_prevention.md) - Template Injection Prevention
- **Related Concept**: [08_0011 Template Engine](../../08_concepts/08_0011_template_engine.md) (to be created)
- **Building Block**: [Section 5.6 Report Generator](../../05_building_block_view/05_building_block_view.md#56-report-generator)
- **Security Scope**: [scope_template_processing_001](../../../04_security/02_scopes/04_template_processing_security.md)

## Evolution from ADR-0005

| Aspect | ADR-0005 (Original) | ADR-0011 (Enhanced) |
|--------|-------------------|-------------------|
| **Variable Substitution** | ✅ `{{variable}}` | ✅ `{{variable}}` (retained) |
| **Conditionals** | ❌ Not supported | ✅ `{{#if}}...{{/if}}` |
| **Loops** | ❌ Not supported | ✅ `{{#each}}...{{/each}}` |
| **Comments** | ❌ Not supported | ✅ `{{! comment}}` |
| **Implementation** | String replacement | State machine parser |
| **Security Controls** | Basic escaping | Defense-in-depth (req_0049) |
| **Complexity** | Low | Medium |
| **User Experience** | Basic | Professional |

**Architectural Progression**: This evolution demonstrates architecture responding to validated requirements while maintaining core principles (Bash implementation, no dependencies, security first).

---

**Status**: Accepted (2026-02-12)  
**Implementation**: feature_0008 (Template Engine Implementation)  
**Next Review**: After implementation, verify security controls and performance characteristics
