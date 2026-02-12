# Feature: Template Engine Implementation

**ID**: 0008  
**Type**: Feature Implementation  
**Status**: Done  
**Created**: 2026-02-09  
**Updated**: 2026-02-12 (Moved to done - implementation complete)
**Priority**: Critical

## Overview
Implement a pure Bash template engine supporting variable substitution, conditionals, loops, and comments to transform workspace metadata into formatted Markdown reports.

## Description
Create a template processing engine that loads Markdown templates with special syntax for dynamic content, substitutes variables from workspace JSON data, evaluates conditionals to handle optional data, iterates over arrays, and generates final Markdown output. The engine must be implemented in pure Bash without external template libraries, handle malformed syntax gracefully, and prevent template injection attacks.

The template engine bridges analysis data and human-readable reports, enabling users to customize report format without modifying core code.

## Business Value
- Enables customizable report formatting without code changes
- Allows non-programmers to create report templates 
- Provides consistent report structure across all analyzed files
- Enables conditional rendering based on available data
- Supports iteration over arrays (tags, plugin results)
- Foundation for report generation feature

## Related Requirements
- [req_0040](../../01_vision/02_requirements/03_accepted/req_0040_template_engine_implementation.md) - Template Engine Implementation (PRIMARY)
- [req_0005](../../01_vision/02_requirements/03_accepted/req_0005_template_based_reporting.md) - Template-based Reporting
- [req_0049](../../01_vision/02_requirements/03_accepted/req_0049_template_injection_prevention.md) - Template Injection Prevention
- [req_0034](../../01_vision/02_requirements/03_accepted/req_0034_template_variable_reference_documentation.md) - Template Variable Reference

## Architecture Review

**Review Date**: 2026-02-12  
**Reviewer**: Architect Agent  
**Status**: ✅ **CONDITIONAL APPROVAL** - Architecture compliant, documentation updates required before "Ready"

**Review Report**: [ARCH_REVIEW_FEATURE_0008_0010_TEMPLATE_AND_REPORT.md](../../ARCH_REVIEW_FEATURE_0008_0010_TEMPLATE_AND_REPORT.md)

### Compliance Summary
- ✅ Aligns with accepted requirements (req_0040, req_0049)
- ✅ Security concept comprehensive (scope_template_processing_001)
- ✅ Component placement appropriate (orchestration layer)
- ✅ Aligns with all architecture constraints (TC_*)

### Architecture Documentation Created
- ✅ [ADR-0011: Bash Template Engine with Control Structures](../../01_vision/03_architecture/09_architecture_decisions/ADR_0011_bash_template_engine_with_control_structures.md)
- ✅ [Concept 08_0011: Template Engine](../../01_vision/03_architecture/08_concepts/08_0011_template_engine.md)
- ✅ Building Block View 5.6 updated with Template Engine sub-component
- ✅ ADR-0005 marked as superseded by ADR-0011

### Security Assessment
- **Risk Level**: HIGH (Template Injection, Risk Score: 174)
- **Mitigation**: Comprehensive defense-in-depth controls present in feature specification
- **Security Review**: REQUIRED after implementation (coordinate with Security Agent)
- **Critical Controls**: No code execution, variable sanitization, iteration limits, timeout enforcement

### Blocking Issues
**NONE** - All architecture documentation complete, feature ready to move to "Ready" state.

### Recommendations
1. Move to "Ready" status - architecture compliant and documented
2. Security Agent review REQUIRED after implementation
3. Fuzz testing with malicious templates (req_0049 acceptance criteria)
4. Consider adding explicit template file size limit (suggest 100KB max)

## Acceptance Criteria

### Template Syntax Support
- [ ] System supports variable substitution: `{{variable_name}}`
- [ ] System supports conditionals: `{{#if variable}}...{{/if}}`
- [ ] System supports loops: `{{#each array}}...{{/each}}`
- [ ] System supports comments: `{{! This is a comment}}`
- [ ] System supports nested conditionals (at least 2 levels deep)
- [ ] System supports nested loops (at least 2 levels deep)
- [ ] System ignores whitespace around template tags

### Variable Substitution
- [ ] System substitutes simple variables: `{{filename}}` → "document.pdf"
- [ ] System substitutes nested variables: `{{content.word_count}}` → "5432"
- [ ] System substitutes array elements in loops: `{{#each tags}}{{this}}{{/each}}`
- [ ] System handles missing variables gracefully (empty string or configurable default)
- [ ] System escapes special characters in substituted values (prevent inadvertent Markdown breaking)
- [ ] System provides built-in helper functions: `{{file_size_human}}`, `{{format_date}}`

### Conditional Logic
- [ ] System evaluates truthiness: non-empty string/array → true, empty/missing → false
- [ ] System renders conditional block only if condition true
- [ ] System skips conditional block if condition false
- [ ] System supports else blocks: `{{#if var}}...{{else}}...{{/if}}`
- [ ] System handles nested conditionals correctly
- [ ] System validates conditional syntax (balanced tags)

### Loop Logic
- [ ] System iterates over arrays: `{{#each array}}...{{/each}}`
- [ ] System provides loop context: `{{this}}` for current item, `{{@index}}` for position
- [ ] System handles nested loops correctly
- [ ] System handles empty arrays gracefully (skip loop block)
- [ ] System validates loop syntax (balanced tags)

### Comment Handling
- [ ] System removes comments from output: `{{! comment}}` → ""
- [ ] Comments can appear anywhere in template
- [ ] Comments do not affect whitespace or line breaks inappropriately

### Error Handling
- [ ] System validates template syntax before processing
- [ ] System reports clear error messages for malformed syntax:
  - Unbalanced conditional tags
  - Unbalanced loop tags
  - Invalid variable references
  - Unknown helper functions
- [ ] System provides line numbers for syntax errors
- [ ] System handles template load failures gracefully
- [ ] System continues with default template if custom template invalid

### Security (Template Injection Prevention)
- [ ] System does NOT execute code in templates (no `eval`, no command substitution)
- [ ] System treats all variable content as data, not code
- [ ] System sanitizes variable substitutions (escape dangerous characters)
- [ ] System enforces iteration limits (max loop iterations to prevent DoS)
- [ ] System implements processing timeout (abort if template takes too long)
- [ ] System validates template does not access filesystem outside allowed paths

### Performance
- [ ] Template processing completes in reasonable time (< 1 second per file for typical templates)
- [ ] Memory usage bounded for large templates or data sets
- [ ] Efficient parsing (single pass or optimized multi-pass)

## Technical Considerations

### Template Syntax Examples
```markdown
# Analysis Report: {{filename}}

## File Information
- **Path**: {{file_path_relative}}
- **Size**: {{file_size_human}}
- **Type**: {{file_type}}
- **Modified**: {{format_date file_last_modified}}

## Content Summary
{{#if content.summary}}
{{content.summary}}
{{else}}
No summary available.
{{/if}}

## Tags
{{#if content.tags}}
{{#each content.tags}}
- {{this}}
{{/each}}
{{else}}
No tags assigned.
{{/if}}

{{! This comment will not appear in output}}

## Analysis Details
- Last scanned: {{format_date last_scanned}}
- Word count: {{content.word_count}}
```

### Implementation Approach
```bash
process_template() {
  local template_file="$1"
  local workspace_data="$2"  # JSON string or file path
  
  # Load template
  local template_content
  template_content=$(<"$template_file") || {
    log "ERROR" "TEMPLATE" "Failed to load template: $template_file"
    return 1
  }
  
  # Validate syntax
  if ! validate_template_syntax "$template_content"; then
    log "ERROR" "TEMPLATE" "Template syntax errors found"
    return 1
  fi
  
  # Parse workspace data into associative array
  declare -A data
  parse_workspace_json "$workspace_data" data
  
  # Process template with security limits
  local output
  local start_time=$SECONDS
  local max_iterations=10000
  local timeout=30
  
  output=$(substitute_variables "$template_content" data) || return 1
  output=$(process_conditionals "$output" data) || return 1
  output=$(process_loops "$output" data "$max_iterations") || return 1
  output=$(remove_comments "$output")
  
  # Check timeout
  if (( SECONDS - start_time > timeout )); then
    log "ERROR" "TEMPLATE" "Template processing timeout exceeded"
    return 1
  fi
  
  echo "$output"
}

substitute_variables() {
  local content="$1"
  declare -n data_ref="$2"
  
  # Find all {{variable}} patterns
  while [[ "$content" =~ \{\{([^}]+)\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local var_value="${data_ref[$var_name]}"
    
    # Sanitize value (escape special chars)
    var_value=$(sanitize_value "$var_value")
    
    # Replace in content
    content="${content/\{\{$var_name\}\}/$var_value}"
  done
  
  echo "$content"
}

process_conditionals() {
  local content="$1"
  declare -n data_ref="$2"
  
  # Process {{#if var}}...{{/if}} blocks
  while [[ "$content" =~ \{\{#if[[:space:]]+([^}]+)\}\}(.*)\{\{/if\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local block_content="${BASH_REMATCH[2]}"
    local var_value="${data_ref[$var_name]}"
    
    # Evaluate truthiness
    local output=""
    if [[ -n "$var_value" ]]; then
      output="$block_content"
    fi
    
    # Replace entire conditional block
    content="${content/\{\{#if $var_name\}\}$block_content\{\{\/if\}\}/$output}"
  done
  
  echo "$content"
}

validate_template_syntax() {
  local template="$1"
  
  # Count opening/closing tags
  local if_open=$(grep -o '{{#if' <<< "$template" | wc -l)
  local if_close=$(grep -o '{{/if}}' <<< "$template" | wc -l)
  local each_open=$(grep -o '{{#each' <<< "$template" | wc -l)
  local each_close=$(grep -o '{{/each}}' <<< "$template" | wc -l)
  
  if (( if_open != if_close )); then
    log "ERROR" "TEMPLATE" "Unbalanced {{#if}}/{{/if}} tags"
    return 1
  fi
  
  if (( each_open != each_close )); then
    log "ERROR" "TEMPLATE" "Unbalanced {{#each}}/{{/each}} tags"
    return 1
  fi
  
  return 0
}

sanitize_value() {
  local value="$1"
  # Escape characters that could break Markdown or enable code execution
  # This is a simplified example; real implementation needs comprehensive escaping
  value="${value//\$/\\$}"  # Escape dollar signs
  value="${value//\`/\\`}"  # Escape backticks
  echo "$value"
}
```

### Integration Points
- **Report Generator**: Uses template engine to produce final reports
- **Workspace Manager**: Provides JSON data for variable substitution
- **CLI**: Accepts template file path via `-m` argument

### Dependencies
- Pure Bash implementation (no external template libraries)
- `jq` for JSON parsing workspace data
- Logging infrastructure for error reporting

### Security Measures
1. **No Code Execution**: Never use `eval` or `$(...)` on template content
2. **Data/Code Separation**: Treat all variables as data, sanitize before substitution
3. **Iteration Limits**: Maximum iterations to prevent infinite loops
4. **Timeout**: Abort processing if exceeds time limit
5. **Input Validation**: Validate template syntax before processing

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Workspace management (feature_0007) - for data source
- Blocks: Report generator (feature_0010) - uses template engine

## Testing Strategy
- Unit tests: Variable substitution with various data types
- Unit tests: Conditional logic (true/false cases, nested)
- Unit tests: Loop logic (arrays, empty arrays, nested)
- Unit tests: Comment removal
- Unit tests: Syntax validation
- Unit tests: Security (injection attempts, DoS attempts)
- Integration tests: Complete template processing with real workspace data
- Integration tests: Error handling for malformed templates
- Performance tests: Large templates, large data sets

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >90% coverage
- [ ] Security tests passing (injection prevention)
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Security review completed
- [ ] Documentation updated (template syntax reference, examples)
- [ ] Performance benchmarks meet targets
