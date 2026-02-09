# Requirement: Template Engine Implementation

**ID**: req_0040

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall implement a template engine supporting variable substitution, conditionals, loops, and comments to transform extracted metadata into formatted Markdown reports.

## Description
Requirements req_0005 and req_0034 establish template-based reporting with variable substitution, but do not define the complete template engine functionality. The CLI Interface Concept (08_0003) specifies template syntax including `{{variable}}` for substitution, `{{#if}}...{{/if}}` for conditionals, `{{#each}}...{{/each}}` for loops, and `{{! comment}}` for comments. Users need these template features to create flexible, comprehensive reports that handle optional data gracefully, iterate over arrays (tags, plugin results), and include explanatory comments. The template engine must be implemented in pure Bash without external dependencies, processing templates efficiently with clear error messages for malformed syntax.

## Motivation
From CLI Interface Concept (08_0003_cli_interface_concept.md):
```
TEMPLATE SYNTAX
  Variables:     {{variable_name}}
  Conditionals:  {{#if variable}}...{{/if}}
  Loops:         {{#each array}}...{{/each}}
  Comments:      {{! This is a comment}}
```

From quality goal (Usability): "Template customization - Non-programmer can create working template in < 30 minutes."

Without a capable template engine, users cannot create sophisticated reports that adapt to varying data availability, iterate over collections, or document template logic with comments.

## Category
- Type: Functional
- Priority: High

## Acceptance Criteria

### Variable Substitution
- [ ] Template engine replaces `{{variable_name}}` with corresponding value from data context
- [ ] Supports nested variable access: `{{content.summary}}`, `{{metadata.author}}`
- [ ] Undefined variables replaced with empty string (no error)
- [ ] Special characters in variable values escaped appropriately for Markdown
- [ ] Variable names support alphanumeric, underscore, dot notation: `{{file_size}}`, `{{metadata.type}}`

### Conditional Rendering
- [ ] `{{#if variable}}...{{/if}}` renders content only if variable is truthy (non-empty, non-zero)
- [ ] `{{#if variable}}...{{else}}...{{/if}}` supports else clause
- [ ] Nested conditionals supported: `{{#if outer}}{{#if inner}}...{{/if}}{{/if}}`
- [ ] Conditional blocks can contain other template syntax (variables, loops)
- [ ] False, empty string, zero, and undefined treated as falsy; all else truthy

### Loop Iteration
- [ ] `{{#each array}}...{{/each}}` iterates over array elements
- [ ] Inside loop, `{{this}}` refers to current element
- [ ] Inside loop, `{{@index}}` provides zero-based iteration index
- [ ] Nested loops supported: iterating over array of objects with sub-arrays
- [ ] Empty arrays result in no output (loop body not rendered)
- [ ] Loop can iterate over object properties treating them as array

### Comments
- [ ] `{{! comment text}}` removed from output (not rendered)
- [ ] Comments can appear anywhere in template (inline or block)
- [ ] Multi-line comments supported: `{{! line 1\nline 2}}`
- [ ] Comments useful for documenting template structure and variable meanings

### Error Handling
- [ ] Malformed template syntax logged with clear error message and line number
- [ ] Unclosed tags (missing `{{/if}}` or `{{/each}}`) detected and reported
- [ ] Template processing errors do not crash toolkit, fail gracefully
- [ ] Verbose mode shows template processing details (variable resolution, conditionals evaluated)

### Performance
- [ ] Template processing completes in < 100ms for typical template (< 500 lines)
- [ ] Template engine handles large variable data (100KB+ content fields) efficiently
- [ ] No external dependencies (pure Bash implementation)

### Integration
- [ ] Template engine used for per-file reports (req_0018)
- [ ] Template engine used for aggregated reports (req_0039)
- [ ] Template receives complete data context from workspace JSON and runtime metadata
- [ ] Template processing errors include template filename for debugging

## Related Requirements
- req_0005 (Template-Based Reporting) - defines template system concept
- req_0034 (Default Template Provision) - default template demonstrates template features
- req_0039 (Aggregated Summary Reports) - uses template engine for summary reports
- req_0004 (Markdown Report Generation) - template output is Markdown

## Technical Considerations

### Template Syntax Examples

**Variable Substitution:**
```markdown
# Analysis Report: {{filename}}
**Path**: {{file_path}}
**Size**: {{file_size_human}}
```

**Conditionals:**
```markdown
{{#if content.summary}}
## Summary
{{content.summary}}
{{else}}
*No summary available*
{{/if}}
```

**Loops:**
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

**Comments:**
```markdown
{{! This section shows file metadata extracted by stat plugin}}
## File Information
- **Modified**: {{modification_time}}
{{! TODO: Add file permissions when available}}
```

### Implementation Strategy

**Parsing Approach:**
- Process template line-by-line with state machine
- Track nesting level for conditionals and loops
- Build output incrementally, appending resolved sections

**Data Context:**
- Accept JSON or associative array as data source
- Use `jq` for JSON path resolution if available
- Fallback to Bash string manipulation for simple cases

**Bash Implementation Considerations:**
```bash
render_template() {
  local template_file="$1"
  local data_json="$2"
  local output=""
  
  # State tracking
  local in_conditional=false
  local conditional_value=""
  local in_loop=false
  local loop_array=""
  
  while IFS= read -r line; do
    # Detect and process template directives
    if [[ "$line" =~ \{\{#if\ ([^}]+)\}\} ]]; then
      # Process conditional
    elif [[ "$line" =~ \{\{#each\ ([^}]+)\}\} ]]; then
      # Process loop
    elif [[ "$line" =~ \{\{([^}]+)\}\} ]]; then
      # Process variable substitution
    else
      # Regular line, append to output
    fi
  done < "$template_file"
  
  echo "$output"
}
```

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from CLI Interface Concept analysis
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
