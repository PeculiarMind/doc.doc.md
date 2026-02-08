# ADR-0005: Template-Based Report Generation

**ID**: ADR-0005  
**Status**: Accepted  
**Created**: 2026-02-06  
**Last Updated**: 2026-02-08

## Context

Need mechanism to generate Markdown reports from analysis data. Reports must be customizable by users without programming knowledge, allowing organizations to apply their own formatting, branding, and structure.

## Decision

Use simple Markdown templates with `{{variable}}` placeholder syntax. Substitute variables with workspace data during report generation using string replacement.

## Rationale

**Strengths**:
- **User-Friendly**: Non-programmers can create/modify templates
- **Separation of Concerns**: Report structure separate from analysis logic
- **Customization**: Organizations can apply branding/standards
- **Version Control**: Plain text templates easily tracked
- **No Dependencies**: Simple string substitution in bash

**Weaknesses**:
- **Limited Logic**: No conditionals, loops, or complex expressions
- **Flat Namespace**: All variables in same scope
- **Error-Prone**: Typos in variable names fail silently

## Alternatives Considered

### Full Template Engine (Jinja2, Mustache)
- ✅ Powerful logic, conditionals, loops
- ❌ Requires additional runtime (Python, etc.)
- ❌ More complex for simple use case
- **Decision**: Overkill for needs, adds dependencies

### Embedded Scripting (Lua, etc.)
- ✅ Full programming in templates
- ❌ Too complex for report templates
- ❌ Security concerns (arbitrary code execution)
- **Decision**: Over-engineered, dangerous

### Markdown with Frontmatter
- ✅ Structured metadata section
- ❌ Still need variable substitution
- ❌ Doesn't solve core problem
- **Decision**: Could complement but doesn't replace

### Direct Code Generation
- ✅ Full control, type-safe
- ❌ Users can't customize without coding
- ❌ Violates separation of concerns
- **Decision**: Not user-friendly

## Consequences

### Positive
- Users create templates in minutes
- No programming knowledge required
- Easy to preview (just Markdown)
- Can use any text editor

### Negative
- Cannot conditionally include sections
- Cannot iterate over arrays
- Limited formatting options

### Risks
- Silent failures when variables misspelled
- Large templates difficult to maintain
- No validation of variable availability

## Implementation Notes

**Template Example**:
```markdown
# Analysis Report: {{file_path}}

**Generated**: {{last_scanned}}

## File Information
- **Type**: {{file_type}}
- **Size**: {{file_size}}
- **Modified**: {{file_last_modified}}
- **Owner**: {{file_owner}}

## Content Analysis
{{content.summary}}

### Statistics
- **Word Count**: {{content.word_count}}
- **Line Count**: {{content.line_count}}

### Tags
{{content.tags}}
```

**Substitution Implementation**:
```bash
substitute_variables() {
  local template="$1"
  local -n data=$2  # Reference to associative array
  
  for key in "${!data[@]}"; do
    template="${template//\{\{${key}\}\}/${data[${key}]}}"
  done
  
  echo "${template}"
}
```

**Mitigation Strategies**:
- Provide multiple template examples
- Document available variables clearly
- Add helper functions for common formatting (dates, sizes)
- For complex needs, generate interim template then use external processor
- Validate templates before execution
- List available variables in verbose mode

## Related Items

- [ADR-0002](ADR_0002_json_workspace_for_state_persistence.md) - JSON workspace provides template data
- REQ-0005: Template-Based Reporting
- Template file: `scripts/template.doc.doc.md`

**Trade-offs Accepted**:
- **Simplicity over Power**: Accept limited templating for ease of use
- **String Replacement over Engine**: Avoid dependencies, keep it simple
- **User Customization over Code Generation**: Empower users to define output
