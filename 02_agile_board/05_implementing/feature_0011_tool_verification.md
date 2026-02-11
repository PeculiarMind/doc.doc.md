# Feature: Tool Availability Verification System

**ID**: 0011  
**Type**: Feature Implementation  
**Status**: Implementing  
**Created**: 2026-02-09  
**Updated**: 2026-02-11 (Moved to implementing)  
**Priority**: High

## Overview
Implement tool availability verification that checks for required CLI tools before analysis, reports missing tools with platform-specific installation guidance, and optionally prompts users to install missing tools in interactive mode.

## Description
Create a tool verification subsystem that discovers what tools plugins require, checks if those tools are available on the system, provides clear reporting of missing dependencies, and offers platform-specific installation guidance. In interactive mode, the system can prompt users to automatically install missing tools using package managers. This feature ensures graceful degradation when optional tools are missing and clear error messages for required tools.

The verification system integrates with plugin descriptors to understand tool dependencies and with platform detection to provide appropriate installation commands.

## Business Value
- Prevents cryptic execution errors by detecting missing tools early
- Reduces user frustration through clear installation guidance
- Enables graceful degradation (skip plugins with missing optional tools)
- Improves onboarding experience with installation prompts
- Supports cross-platform deployment with platform-specific guidance

## Related Requirements
- [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification (PRIMARY)
- [req_0008](../../01_vision/02_requirements/03_accepted/req_0008_installation_prompts.md) - Installation Prompts
- [req_0045](../../01_vision/02_requirements/03_accepted/req_0045_non_interactive_mode_handling.md) - Non-interactive Mode (impacts prompts)
- [req_0010](../../01_vision/02_requirements/03_accepted/req_0010_unix_tool_composability.md) - Unix Tool Composability

## Acceptance Criteria

### Tool Discovery
- [ ] System analyzes all active plugin descriptors to extract required tools
- [ ] System reads `check_commandline` field from each plugin descriptor per unified schema (ADR-0010)
- [ ] System executes check commands in safe environment (no variable substitution)
- [ ] System categorizes tools as: available, missing_optional, missing_required
- [ ] System logs tool discovery process in verbose mode
- [ ] System validates check commands follow security patterns (no injection vulnerabilities)

### Tool Availability Check
- [ ] System checks each tool using descriptor's `check_commandline` (e.g., `command -v jq`)
- [ ] System caches availability results with 5-minute TTL to avoid repeated checks
- [ ] System invalidates cache on plugin descriptor changes or installation events
- [ ] System handles check command failures gracefully (treat as not available)
- [ ] System provides summary of available and missing tools
- [ ] System checks core system tools (bash, find, stat, file, etc.)
- [ ] System persists cache across tool verification runs for performance

### Missing Tool Reporting
- [ ] System reports missing required tools with clear error messages
- [ ] System reports missing optional tools with informational warnings
- [ ] System includes tool name, purpose, and which plugin requires it
- [ ] System provides installation commands for detected platform
- [ ] System categorizes report by severity (critical, warning, info)

### Platform-Specific Installation Guidance
- [ ] System detects platform using platform detection (ubuntu, debian, darwin, alpine, generic)
- [ ] System provides package manager commands for detected platform:
  - Ubuntu/Debian: `apt-get install <package>`
  - macOS: `brew install <package>`
  - Alpine: `apk add <package>`
  - Generic: Fallback guidance (build from source, manual install)
- [ ] System reads installation commands from plugin descriptors (`install_commandline` field per ADR-0010)
- [ ] System handles multiple installation methods per tool (package manager, script, manual)
- [ ] System validates install commands for security compliance (package manager only, no direct downloads)
- [ ] System validates package manager commands use approved patterns (apt-get, yum, dnf, brew, apk)
- [ ] System rejects installation commands with shell injection patterns (pipes, redirects, command substitution)
- [ ] System validates installation commands don't attempt privilege escalation outside package managers

### Interactive Installation Prompts
- [ ] System detects if running in interactive mode (stdin/stdout are TTY)
- [ ] In interactive mode: System prompts user for each missing tool: "Install <tool>? [y/N]"
- [ ] System executes installation command if user confirms (runs `install_commandline` from descriptor)
- [ ] System validates installation succeeded after execution (re-run check command)
- [ ] System handles installation failures gracefully (log error, continue)
- [ ] System validates install commands are safe before execution (ADR-0009 security compliance)
- [ ] System requires root/sudo for system-wide installations (provides guidance)

### Non-Interactive Behavior
- [ ] In non-interactive mode: System logs missing tools, does NOT prompt
- [ ] System skips plugins with missing required tools (log warning)
- [ ] System continues with available plugins
- [ ] System exits with error code if critical tools missing
- [ ] System provides comprehensive log of what was skipped and why

### Plugin Integration
- [ ] System marks plugins as active/inactive based on tool availability
- [ ] System skips inactive plugins during execution
- [ ] System provides plugin status report: available, missing_deps, inactive
- [ ] System logs which plugins skipped due to missing tools

### Error Handling
- [ ] System handles check command failures (treat as tool not available)
- [ ] System handles installation command failures (log error, continue)
- [ ] System handles permission errors during installation (guidance to use sudo)
- [ ] System provides actionable error messages for all failures
- [ ] System validates installation command integrity before execution (prevent descriptor tampering)
- [ ] System handles corrupted or malicious installation commands gracefully (quarantine plugin)
- [ ] System logs all installation attempts for security audit trail

## Technical Considerations

### Implementation Approach
```bash
verify_tools() {
  local plugins_dir="$1"
  local interactive="${2:-false}"
  
  declare -A tools_status  # tool_name -> available/missing
  declare -A tools_plugins # tool_name -> plugin_names[]
  declare -A tools_install # tool_name -> install_command
  
  # Discover required tools from plugins
  while IFS= read -r descriptor_file; do
    local plugin_name
    plugin_name=$(jq -r '.name' "$descriptor_file")
    
    # Extract tool check command
    local check_cmd
    check_cmd=$(jq -r '.check_commandline // empty' "$descriptor_file")
    
    if [[ -n "$check_cmd" ]]; then
      # Execute check command
      local tool_name
      tool_name=$(extract_tool_name "$check_cmd")
      
      if eval "$check_cmd" &>/dev/null; then
        tools_status["$tool_name"]="available"
        log "DEBUG" "TOOLCHECK" "$tool_name: available"
      else
        tools_status["$tool_name"]="missing"
        tools_plugins["$tool_name"]+="$plugin_name "
        
        # Extract installation command
        local install_cmd
        install_cmd=$(jq -r '.install_commandline // empty' "$descriptor_file")
        tools_install["$tool_name"]="$install_cmd"
        
        log "WARN" "TOOLCHECK" "$tool_name: missing (required by $plugin_name)"
      fi
    fi
  done < <(find "$plugins_dir" -name 'descriptor.json')
  
  # Report missing tools
  local missing_count=0
  for tool_name in "${!tools_status[@]}"; do
    if [[ "${tools_status[$tool_name]}" == "missing" ]]; then
      ((missing_count++))
      
      echo "Missing tool: $tool_name"
      echo "  Required by: ${tools_plugins[$tool_name]}"
      echo "  Install: ${tools_install[$tool_name]}"
      
      # Prompt for installation if interactive
      if [[ "$interactive" == "true" ]]; then
        prompt_install "$tool_name" "${tools_install[$tool_name]}"
      fi
    fi
  done
  
  return $missing_count
}

prompt_install() {
  local tool_name="$1"
  local install_cmd="$2"
  
  if [[ -z "$install_cmd" ]]; then
    log "INFO" "TOOLCHECK" "No automatic installation available for $tool_name"
    return 1
  fi
  
  read -p "Install $tool_name? [y/N] " -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    log "INFO" "TOOLCHECK" "Installing $tool_name..."
    
    if eval "$install_cmd"; then
      log "INFO" "TOOLCHECK" "$tool_name installed successfully"
      return 0
    else
      log "ERROR" "TOOLCHECK" "Failed to install $tool_name"
      return 1
    fi
  fi
  
  return 1
}

extract_tool_name() {
  local check_cmd="$1"
  # Extract tool name from check command (e.g., "command -v jq" -> "jq")
  if [[ "$check_cmd" =~ command[[:space:]]+-v[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$check_cmd" =~ which[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "unknown"
  fi
}

get_platform_install_command() {
  local tool_name="$1"
  local platform="$2"
  
  case "$platform" in
    ubuntu|debian)
      echo "sudo apt-get install -y $tool_name"
      ;;
    darwin)
      echo "brew install $tool_name"
      ;;
    alpine)
      echo "apk add $tool_name"
      ;;
    *)
      echo "# Please install $tool_name manually for your platform"
      return 1
      ;;
  esac
}
```

### Plugin Descriptor Integration
```json
{
  "name": "ocrmypdf",
  "description": "OCR for PDF files",
  "active": true,
  "check_commandline": "command -v ocrmypdf >/dev/null 2>&1",
  "install_commandline": "sudo apt-get install -y ocrmypdf tesseract-ocr",
  "consumes": ["file_path_absolute"],
  "provides": ["ocr_text_content"]
}
```

### Integration Points
- **Plugin Manager**: Uses tool verification before plugin activation
- **Platform Detection**: Provides platform for installation commands
- **Interactive Mode Detection**: Determines whether to prompt
- **Logging System**: Reports tool status

### Dependencies
- Plugin discovery (feature_0003) ✅
- Platform detection (feature_0001) ✅
- Logging infrastructure (feature_0001) ✅

### Performance Considerations
- Cache tool availability results (avoid repeated checks)
- Batch tool checks where possible
- Quick check commands (use `command -v`, not full execution)

### Security Considerations
- Validate installation commands from descriptors (no arbitrary shell execution)
- Require user confirmation before installing
- Warn about sudo requirements
- Log all installation attempts
- Validate tool available after installation

## Dependencies
- Requires: Basic script structure (feature_0001) ✅
- Requires: Plugin listing (feature_0003) ✅
- Blocks: Plugin execution (feature_0009) - must verify tools first

## Testing Strategy
- Unit tests: Tool discovery from descriptors
- Unit tests: Tool availability checking
- Unit tests: Platform detection for install commands
- Integration tests: Interactive installation prompt
- Integration tests: Non-interactive behavior
- Integration tests: Mixed available/missing tools
- Integration tests: Installation failure handling

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests passing with >80% coverage
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] User documentation for tool requirements
- [ ] Platform-specific installation guides created

## Architecture Review

**Reviewed**: 2026-02-11  
**Reviewer**: Architect Agent  
**Architecture Decision Record**: [IDR-0016](../../03_documentation/01_architecture/09_architecture_decisions/IDR_0016_plugin_execution_engine_implementation.md)

### Compliance Status

| ADR | Status | Notes |
|-----|--------|-------|
| ADR-0010 (Interface) | ✅ Compliant | Uses `check_commandline` from descriptors per unified schema |
| ADR-0007 (Modular) | ✅ Compliant | Component at 223 lines, close to 200-line target |
| ADR-0009 (Sandbox) | N/A | Tool checks run outside sandbox (availability verification only) |

### Deviations

None identified. The use of `bash -c` for executing `check_commandline` is acceptable for availability checks since these commands only verify tool presence (e.g., `which stat`) and do not process untrusted data or modify state.

### Positive Findings

- Platform-aware installation guidance reuses existing `platform_detection.sh`
- Interactive prompts gated on TTY detection (safe in non-interactive/CI environments)
- Tool status integrates cleanly with executor plugin-skip logic
- Minimal component size with focused responsibility

### Assessment

**Result**: ✅ **APPROVED - FULLY COMPLIANT**

## Security Review

**Reviewed**: 2026-02-11  
**Reviewer**: Security Review Agent

### Security Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | LOW | `check_tool_availability()` uses `bash -c` to execute `check_commandline` which could run arbitrary code if a descriptor is malicious. Mitigated by validator screening descriptors before tool checker runs. |
| 2 | LOW | `prompt_tool_install()` uses `bash -c` to execute `install_commandline`. Mitigated by validator restricting to recognized package managers and requiring user confirmation before execution. |
| 3 | INFO | TTY check properly guards interactive prompts — installation prompts are suppressed in non-interactive and CI environments. |

### Risk Assessment

- **Primary Risk**: Command execution via `bash -c` is inherent to the tool checking design. Risk is acceptable because the validator (Feature 0012) screens all descriptors for injection patterns before tool checking occurs.
- **Residual Risk**: Low. The attack path requires bypassing the validator's injection pattern detection, which covers `;`, `&&`, `||`, `$()`, backticks, `eval`, `bash -c`, and `sh -c`.

### Security Agent Verdict

**APPROVED**

## Test Assessment

**Reviewed**: 2026-02-11  
**Reviewer**: Tester Agent

### Test Coverage Status

| Test File | Tests | Status |
|-----------|-------|--------|
| test_tool_verification.sh | 8 | ✅ All passing |

### Coverage Details
- ✅ Available tool detection (e.g., bash detected as available)
- ✅ Missing tool detection (nonexistent tools reported as missing)
- ✅ Status report generation (summary of available/missing tools)
- ✅ Platform-specific install guidance (package manager commands)
- ✅ verify_plugin_tools descriptor processing
- ✅ Edge cases (empty check_commandline, check command failures)

### Coverage Gaps
- ⚠️ Interactive installation prompt tests not implemented (TTY dependency)
- ⚠️ Tool availability caching (5-minute TTL) not tested
- ⚠️ Cache invalidation on descriptor changes not tested

### References
- **Test Plan**: [testplan_feature_0009_0011_0012_plugin_execution_system.md](../../03_documentation/02_tests/testplan_feature_0009_0011_0012_plugin_execution_system.md)
- **Test Report**: [testreport_feature_0009_0011_0012_0020_20260211.01.md](../../03_documentation/02_tests/testreport_feature_0009_0011_0012_0020_20260211.01.md)
