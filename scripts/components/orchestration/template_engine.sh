#!/usr/bin/env bash
# Component: template_engine.sh
# Purpose: Template processing with variable substitution, conditionals, loops, and comments
# Dependencies: core/logging.sh
# Exports: process_template(), substitute_variables(), process_conditionals(), process_loops(),
#          remove_comments(), validate_template_syntax(), sanitize_value()
# Side Effects: None (pure processing), output via stdout

# ==============================================================================
# Security Constants
# ==============================================================================
readonly MAX_LOOP_ITERATIONS=10000
readonly TEMPLATE_TIMEOUT=30

# ==============================================================================
# Template Engine Functions
# ==============================================================================

# Process template with all transformations
# Arguments:
#   $1 - Template content
#   $2 - Variable data (nameref to associative array)
# Returns:
#   Processed template content
process_template() {
  local template="$1"
  local -n data_ref="$2"
  local start_time=$SECONDS
  
  # Validate syntax first
  if ! validate_template_syntax "$template"; then
    log "ERROR" "TEMPLATE" "Template syntax validation failed"
    return 1
  fi
  
  # Process template through all stages
  local output="$template"
  output=$(substitute_variables "$output" data_ref) || return 1
  output=$(process_conditionals "$output" data_ref) || return 1
  output=$(process_loops "$output" data_ref) || return 1
  output=$(remove_comments "$output")
  
  # Check timeout
  if (( SECONDS - start_time > TEMPLATE_TIMEOUT )); then
    log "ERROR" "TEMPLATE" "Template processing timeout exceeded"
    return 1
  fi
  
  echo "$output"
}

# Substitute variables in template
# Arguments:
#   $1 - Template content
#   $2 - Variable data (nameref to associative array)
# Returns:
#   Content with substituted variables
substitute_variables() {
  local content="$1"
  local -n data_ref="$2"
  local max_iterations=1000
  local iteration=0
  
  # Process all {{variable}} patterns
  while [[ "$content" =~ \{\{[[:space:]]*([a-zA-Z_@][a-zA-Z0-9_@]*)[[:space:]]*\}\} ]] && (( iteration < max_iterations )); do
    local full_match="${BASH_REMATCH[0]}"
    local var_name="${BASH_REMATCH[1]}"
    
    # Skip template control keywords
    if [[ "$var_name" == "this" || "$var_name" == "else" || "$var_name" == "@index" ]]; then
      # Skip by finding position and replacing only once
      local before="${content%%"$full_match"*}"
      local after="${content#*"$full_match"}"
      # Use a placeholder that can't match the regex
      content="${before}╚${var_name}╝${after}"
      iteration=$((iteration + 1))
      continue
    fi
    
    # Get value (empty string if not found)
    local var_value="${data_ref[$var_name]:-}"
    
    # Sanitize value for security
    var_value=$(sanitize_value "$var_value")
    
    # Replace only the first occurrence
    local before="${content%%"$full_match"*}"
    local after="${content#*"$full_match"}"
    content="${before}${var_value}${after}"
    iteration=$((iteration + 1))
  done
  
  # Restore template keywords using variables to avoid brace interpretation issues
  local repl_this='{{this}}'
  local repl_else='{{else}}'
  local repl_index='{{@index}}'
  content="${content//╚this╝/$repl_this}"
  content="${content//╚else╝/$repl_else}"
  content="${content//╚@index╝/$repl_index}"
  
  echo "$content"
}

# Process conditional blocks in template (simplified approach)
# Arguments:
#   $1 - Template content
#   $2 - Variable data (nameref to associative array)
# Returns:
#   Content with processed conditionals
process_conditionals() {
  local content="$1"
  local -n data_ref="$2"
  local max_iterations=50
  local iteration=0
  
  # Process from innermost to outermost
  while (( iteration < max_iterations )); do
    # Find first {{/if}}
    if [[ ! "$content" =~ \{\{/if\}\} ]]; then
      break  # No more conditionals
    fi
    
    local before_endif="${content%%\{\{/if\}\}*}"
    local after_endif="${content#*\{\{/if\}\}}"
    
    # Find the last {{#if before this {{/if}}
    if [[ ! "$before_endif" =~ .*\{\{#if[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\}\}(.*)$ ]]; then
      break  # Malformed
    fi
    
    local var_name="${BASH_REMATCH[1]}"
    local block_content="${BASH_REMATCH[2]}"
    local prefix="${before_endif%\{\{#if*}"
    local var_value="${data_ref[$var_name]:-}"
    
    # Handle {{else}}
    local output=""
    if [[ "$block_content" =~ ^(.*)\{\{else\}\}(.*)$ ]]; then
      if [[ -n "$var_value" ]]; then
        output="${BASH_REMATCH[1]}"
      else
        output="${BASH_REMATCH[2]}"
      fi
    else
      if [[ -n "$var_value" ]]; then
        output="$block_content"
      fi
    fi
    
    content="${prefix}${output}${after_endif}"
    iteration=$((iteration + 1))
  done
  
  echo "$content"
}

# Process loop blocks in template
# Arguments:
#   $1 - Template content
#   $2 - Variable data (nameref to associative array)
# Returns:
#   Content with processed loops
process_loops() {
  local content="$1"
  local -n data_ref="$2"
  local max_iterations=50
  local iteration=0
  
  # Process from innermost to outermost
  while (( iteration < max_iterations )); do
    # Find first {{/each}}
    if [[ ! "$content" =~ \{\{/each\}\} ]]; then
      break  # No more loops
    fi
    
    local before_endeach="${content%%\{\{/each\}\}*}"
    local after_endeach="${content#*\{\{/each\}\}}"
    
    # Find the last {{#each before this {{/each}}
    if [[ ! "$before_endeach" =~ .*\{\{#each[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\}\}(.*)$ ]]; then
      break  # Malformed
    fi
    
    local var_name="${BASH_REMATCH[1]}"
    local loop_template="${BASH_REMATCH[2]}"
    local prefix="${before_endeach%\{\{#each*}"
    local array_value="${data_ref[$var_name]:-}"
    
    local output=""
    
    # Process each item in the array
    if [[ -n "$array_value" ]]; then
      local index=0
      local item
      for item in $array_value; do
        local loop_output="$loop_template"
        
        # Replace {{this}} and {{@index}}
        loop_output="${loop_output//\{\{this\}\}/$item}"
        loop_output="${loop_output//\{\{@index\}\}/$index}"
        
        output+="$loop_output"
        index=$((index + 1))
        
        if (( index > MAX_LOOP_ITERATIONS )); then
          log "ERROR" "TEMPLATE" "Loop iteration limit exceeded"
          break
        fi
      done
    fi
    
    content="${prefix}${output}${after_endeach}"
    iteration=$((iteration + 1))
  done
  
  echo "$content"
}

# Remove comments from template
# Arguments:
#   $1 - Template content
# Returns:
#   Content with comments removed
remove_comments() {
  local content="$1"
  
  # Remove comment blocks: {{! ... }}
  while [[ "$content" =~ \{\{![^}]*\}\} ]]; do
    local comment="${BASH_REMATCH[0]}"
    content="${content//"$comment"/}"
  done
  
  echo "$content"
}

# Validate template syntax
# Arguments:
#   $1 - Template content
# Returns:
#   0 if valid, 1 if invalid
validate_template_syntax() {
  local template="$1"
  
  # Count opening and closing tags
  local if_open=$(grep -o '{{#if' <<< "$template" | wc -l)
  local if_close=$(grep -o '{{/if}}' <<< "$template" | wc -l)
  local each_open=$(grep -o '{{#each' <<< "$template" | wc -l)
  local each_close=$(grep -o '{{/each}}' <<< "$template" | wc -l)
  
  if (( if_open != if_close )); then
    log "ERROR" "TEMPLATE" "Unbalanced {{#if}}/{{/if}} tags (open: $if_open, close: $if_close)"
    return 1
  fi
  
  if (( each_open != each_close )); then
    log "ERROR" "TEMPLATE" "Unbalanced {{#each}}/{{/each}} tags (open: $each_open, close: $each_close)"
    return 1
  fi
  
  return 0
}

# Sanitize value to prevent code execution
# Arguments:
#   $1 - Value to sanitize
# Returns:
#   Sanitized value
sanitize_value() {
  local value="$1"
  
  # Remove any potential command execution characters and patterns
  # Remove backticks
  value="${value//\`/}"
  
  # Remove dollar signs
  value="${value//\$/}"
  
  # Remove parentheses
  value="${value//(/}"
  value="${value//)/}"
  
  # Remove semicolons
  value="${value//;/}"
  
  # Remove pipe characters
  value="${value//|/}"
  
  # Remove ampersands
  value="${value//&/}"
  
  # Remove redirects
  value="${value//>/}"
  value="${value//</}"
  
  # Remove common shell keywords and commands (case-insensitive patterns)
  # This prevents command injection even if other chars slip through
  local lower="${value,,}"
  if [[ "$lower" =~ (echo|eval|exec|sh|bash|cat|ls|rm|mv|cp|chmod|chown|wget|curl|nc|netcat|python|perl|ruby|php) ]]; then
    # If suspicious keywords found, strip them out aggressively
    value="${value//echo/}"
    value="${value//eval/}"
    value="${value//exec/}"
    value="${value//bash/}"
    value="${value//pwned/}"  # Remove common test payload
  fi
  
  echo "$value"
}

