# Feature: User Prompt and Confirmation System

**ID**: 0018  
**Type**: Feature Implementation  
**Status**: Backlog  
**Created**: 2026-02-10  
**Updated**: 2026-02-10 (Moved to backlog - approved by architect review)  
**Priority**: Medium

## Overview
Implement user prompt and confirmation system for interactive mode that allows users to make decisions about optional operations, tool installation, and other potentially disruptive actions.

## Description
Create a prompt system that enables interactive users to control toolkit behavior through clear yes/no or option-based confirmations. Prompts only appear in interactive mode and include clear default options (e.g., [y/N] where N is default), handle invalid responses gracefully with re-prompting, and allow users to decline optional operations without failing the entire workflow.

The system provides standardized prompt functions for common scenarios (tool installation, directory creation) while remaining flexible for custom prompts. All prompts are automatically suppressed in non-interactive mode where automatic defaults apply instead.

## Business Value
- Gives users control over potentially disruptive operations
- Prevents unwanted tool installations or system modifications
- Improves trust by being transparent about actions requiring approval
- Reduces risk of unintended consequences from automated decisions
- Supports informed user decisions through clear prompt messages

## Related Requirements
- [req_0057](../../01_vision/02_requirements/03_accepted/req_0057_interactive_mode_behavior.md) - Interactive Mode Behavior (PRIMARY)
- [req_0008](../../01_vision/02_requirements/03_accepted/req_0008_installation_prompts.md) - Installation Prompts

## Acceptance Criteria

### Core Prompt Functionality
- [ ] System provides `prompt_yes_no()` function for yes/no confirmations
- [ ] Prompts only display in interactive mode (`IS_INTERACTIVE=true`)
- [ ] Prompts suppressed completely in non-interactive mode (returns default automatically)
- [ ] Prompt message clearly states what action requires confirmation
- [ ] Default option clearly indicated (e.g., [y/N] means 'no' is default)

### Response Handling
- [ ] System accepts 'y', 'Y', 'yes', 'Yes', 'YES' as affirmative responses
- [ ] System accepts 'n', 'N', 'no', 'No', 'NO' as negative responses
- [ ] Empty response (just Enter) uses default option
- [ ] Invalid responses trigger re-prompt with guidance ("Please enter y or n:")
- [ ] System does not loop indefinitely (max 3 attempts, then use default)

### Prompt Types
- [ ] **Yes/No prompt**: Binary choice with default option
- [ ] **Tool installation prompt**: "Install missing tool X? [y/N]"
- [ ] **Directory creation prompt**: "Create target directory? [Y/n]"
- [ ] Custom prompts supported through common prompt function

### Non-Interactive Behavior
- [ ] In non-interactive mode, prompts return default immediately without blocking
- [ ] Default decision logged for audit trail
- [ ] Clear log message indicates automatic decision ("Auto-declining tool installation (non-interactive mode)")

### User Experience
- [ ] Prompt text formatted for readability (clear question, context if needed)
- [ ] Cursor positioned at end of prompt for immediate typing
- [ ] Response echoed back to terminal (standard `read` behavior)
- [ ] Outcome logged after user decision ("User approved tool installation" or "User declined migration")

### Integration Points
- [ ] Tool verification system uses prompts for missing tool installation
- [ ] Directory scanner uses prompts for target directory creation
- [ ] Plugin system uses prompts for installing plugin dependencies

## Technical Considerations

### Implementation
```bash
# Core prompt function
prompt_yes_no() {
  local message="$1"
  local default="${2:-n}"  # Default to 'n' if not specified
  local response
  local attempts=0
  local max_attempts=3
  
  # Non-interactive mode: return default immediately
  if [[ "${IS_INTERACTIVE}" != "true" ]]; then
    log "DEBUG" "PROMPT" "Auto-answering prompt with default '${default}' (non-interactive mode)"
    [[ "${default}" =~ ^[Yy]$ ]] && return 0 || return 1
  fi
  
  # Format prompt with default indicator
  local prompt_display
  if [[ "${default}" =~ ^[Yy]$ ]]; then
    prompt_display="${message} [Y/n] "
  else
    prompt_display="${message} [y/N] "
  fi
  
  # Interactive prompt loop
  while (( attempts < max_attempts )); do
    read -p "${prompt_display}" response
    
    # Empty response = default
    if [[ -z "${response}" ]]; then
      response="${default}"
    fi
    
    # Check response
    case "${response}" in
      [Yy]|[Yy][Ee][Ss])
        log "DEBUG" "PROMPT" "User responded: yes"
        return 0
        ;;
      [Nn]|[Nn][Oo])
        log "DEBUG" "PROMPT" "User responded: no"
        return 1
        ;;
      *)
        echo "Please enter 'y' or 'n'."
        ((attempts++))
        ;;
    esac
  done
  
  # Max attempts exceeded, use default
  log "WARN" "PROMPT" "Max prompt attempts exceeded, using default: ${default}"
  [[ "${default}" =~ ^[Yy]$ ]] && return 0 || return 1
}

# Usage examples
if prompt_yes_no "Install missing tool 'ocrmypdf'?" "n"; then
  install_ocrmypdf
  log "INFO" "TOOL" "User approved ocrmypdf installation"
else
  log "INFO" "TOOL" "User declined ocrmypdf installation, skipping plugin"
fi

```

### Specialized Prompt Functions
```bash
# Prompt for tool installation
prompt_tool_installation() {
  local tool_name="$1"
  local install_command="$2"
  
  if prompt_yes_no "Install missing tool '${tool_name}'?" "n"; then
    log "INFO" "TOOL" "Installing ${tool_name}..."
    eval "${install_command}"
    return $?
  else
    return 1
  fi
}

```

### Testing Support
```bash
# Mock prompt responses for testing
export DOC_DOC_PROMPT_RESPONSE="y"  # Force all prompts to answer 'yes'
export DOC_DOC_PROMPT_RESPONSE="n"  # Force all prompts to answer 'no'

# In prompt function, check for test override
if [[ -n "${DOC_DOC_PROMPT_RESPONSE}" ]]; then
  response="${DOC_DOC_PROMPT_RESPONSE}"
  log "DEBUG" "PROMPT" "Using test response: ${response}"
fi
```

## Dependencies
- **feature_0016** (Mode Detection) - Must know if interactive before showing prompts
- Logging system for recording user decisions

## Estimated Effort
Small (2-3 hours) - Straightforward prompt logic, response validation, testing hooks

## Notes
- Prompts block execution waiting for user input - this is intentional in interactive mode
- Consider timeout for prompts in case user walks away (default after 60 seconds?)
- Future enhancement: Support for multi-option prompts (1/2/3 choice menus)
- Ensure prompts work correctly when stdin/stdout redirected

## Transition History
- [2026-02-10] Created by Requirements Engineer Agent - derived from req_0057 Interactive Mode Behavior
