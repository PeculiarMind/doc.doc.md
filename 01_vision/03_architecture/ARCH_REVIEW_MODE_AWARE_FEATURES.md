# Architecture Review: Mode-Aware Behavior Features

**Review Date**: 2026-02-10  
**Reviewer**: Architect Agent  
**Features Reviewed**: 
- feature_0016 (Mode Detection)
- feature_0017 (Interactive Progress Display)
- feature_0018 (User Prompt System)
- feature_0019 (Structured Logging)

**Related Requirements**: req_0057 (Interactive Mode Behavior), req_0058 (Non-Interactive Mode Behavior)

## Executive Summary

The four features under review introduce **mode-aware behavioral adaptation** as a fundamental cross-cutting architectural concern. This is a significant architectural enhancement that enables the system to serve dual use cases (interactive users and automated systems) with a single codebase while maintaining quality goals for both contexts.

**Architecture Impact**: HIGH - Affects multiple layers, introduces new components, requires coordination across existing components

**Risk Level**: MEDIUM - Implementation complexity in coordination, but well-established pattern used by mature CLI tools

**Recommendation**: APPROVE with implementation guidelines

---

## Architectural Analysis

### 1. Core Architectural Pattern: Mode-Aware Behavior

**Pattern Description**: The system detects execution context early (interactive vs. non-interactive) and adapts behavior throughout its lifecycle based on this context.

**Significance**:
- This is a **cross-cutting concern** affecting all user-facing components
- Establishes a **foundational infrastructure component** (mode detection) that other components depend on
- Enables meeting **Reliability Quality Goal R1** (cron job execution)
- Follows **industry standard pattern** (git, docker, npm use identical approach)

**Architecture Vision Alignment**:
- ✅ Aligns with UNIX philosophy (do one thing well, composable)
- ✅ Supports "Reliability" quality goal (unattended operation)
- ✅ Enhances "Usability" quality goal (rich interactive experience)
- ✅ Compatible with existing modular architecture (ADR-0007)
- ✅ Consistent with Bash implementation (ADR-0001)

### 2. New Architectural Components

#### 2.1 Mode Detection Component
- **Location**: `scripts/components/core/mode_detection.sh`
- **Responsibility**: Detect interactive vs. non-interactive context using POSIX terminal tests
- **Integration**: Must be loaded first in component initialization order
- **Key Interface**: `detect_interactive_mode()` function, `IS_INTERACTIVE` global variable
- **Dependencies**: None (foundational component)

#### 2.2 Progress Display Component
- **Location**: `scripts/components/ui/progress_display.sh`
- **Responsibility**: Render live in-place progress bars and status (interactive mode only)
- **Integration**: Called by orchestrator during long-running operations
- **Key Interfaces**: `show_progress()`, `clear_progress()`, `render_progress_bar()`
- **Dependencies**: Mode Detection, Logging

#### 2.3 Prompt System Component
- **Location**: `scripts/components/ui/prompt_system.sh`
- **Responsibility**: Interactive user confirmations and decisions
- **Integration**: Used by plugin manager, workspace manager for optional operations
- **Key Interfaces**: `prompt_yes_no()`, `prompt_tool_installation()`, `prompt_workspace_migration()`
- **Dependencies**: Mode Detection, Logging

### 3. Enhanced Existing Components

#### 3.1 Logging Component Enhancement
**Current State**: Basic logging with verbose flag  
**Required Enhancements**:
- Mode-aware output formatting (structured vs. human-friendly)
- ISO 8601 timestamps in non-interactive mode
- Component tagging system (INIT, SCAN, PLUGIN, etc.)
- Milestone-based progress logging for non-interactive mode
- ANSI color suppression in non-interactive mode

#### 3.2 Other Component Integrations
All user-facing components must be updated to check `IS_INTERACTIVE` before:
- Displaying progress/status
- Prompting for input
- Using ANSI escape codes
- Formatting output

**Affected Components**:
- `ui/argument_parser.sh` - Error message formatting
- `ui/help_system.sh` - Output formatting
- `plugin/plugin_discovery.sh` - Tool installation prompts
- `plugin/plugin_executor.sh` - Progress reporting
- `orchestration/scanner.sh` - Progress updates
- `orchestration/report_generator.sh` - Status output

---

## Architecture Vision Updates Made

### Documents Created

1. **[08_0010_mode_aware_behavior.md](../08_concepts/08_0010_mode_aware_behavior.md)** - Comprehensive concept document
   - Purpose, rationale, detection strategy
   - Behavioral adaptations by mode (table format)
   - Component integration patterns
   - Implementation guidelines and anti-patterns
   - Testing support and mode override

2. **[ADR_0008_posix_terminal_test_for_mode_detection.md](../09_architecture_decisions/ADR_0008_posix_terminal_test_for_mode_detection.md)** - Architecture decision
   - Context: Why mode detection is needed
   - Decision: POSIX terminal tests (`[ -t 0 ] && [ -t 1 ]`)
   - Alternatives considered (9 alternatives analyzed)
   - Consequences, risks, implementation notes

### Documents Updated

3. **[05_building_block_view.md](../05_building_block_view/05_building_block_view.md)** - Building block additions
   - Updated system overview diagram with mode-aware components
   - Added Core Infrastructure layer
   - Added detailed sections for Mode Detection (5.7), Progress Display (5.8), Prompt System (5.9)
   - Updated cross-cutting concepts section (5.10)
   - Added design decisions (5.11)

4. **[04_solution_strategy.md](../04_solution_strategy/04_solution_strategy.md)** - Strategy enhancement
   - Added "Mode-Aware Behavioral Adaptation" as core decision #6
   - Updated "Reliability" quality goal achievement strategy
   - Updated "Usability" quality goal achievement strategy

5. **[09_architecture_decisions.md](../09_architecture_decisions/09_architecture_decisions.md)** - ADR index
   - Added ADR-0008 to the index table

6. **[01_introduction_and_goals.md](../01_introduction_and_goals/01_introduction_and_goals.md)** - Requirements list
   - Updated requirement count (37 → 39)
   - Added req_0057 and req_0058 to accepted requirements list

---

## Implementation Recommendations

### Priority 1: Foundation (Implement First)

**1. Mode Detection Component** (feature_0016)
- Must be implemented first as all other features depend on it
- Load order: First component loaded after constants
- Global variable `IS_INTERACTIVE` must be set early
- Environment override `DOC_DOC_INTERACTIVE` for testing

**Implementation Order**: Core initialization → Mode detection → Export global

### Priority 2: Logging Enhancement (Implement Second)

**2. Structured Logging** (feature_0019)
- Enhance existing `core/logging.sh`
- Add mode-aware formatting function
- Implement component tagging
- Add milestone logging for non-interactive mode

**Implementation Order**: Refactor log() → Add structured format → Test both modes

### Priority 3: User Interface Components (Implement Third)

**3. Progress Display** (feature_0017)
- Create new `ui/progress_display.sh`
- Implement progress bar rendering
- Add terminal width detection
- Integrate with file scanner and orchestrator

**4. Prompt System** (feature_0018)
- Create new `ui/prompt_system.sh`
- Implement yes/no prompt with retries
- Add specialized prompt functions
- Integrate with plugin manager and workspace manager

**Implementation Order**: Can be done in parallel after Priority 1 & 2 complete

### Priority 4: Integration (Implement Last)

**5. Component Updates**
- Update all user-facing components to check `IS_INTERACTIVE`
- Replace existing prompt calls with prompt system
- Replace progress output with progress display or milestone logging
- Update error messages to be mode-aware

**Anti-Patterns to Avoid**:
- ❌ Never block on user input without checking mode
- ❌ Never use ANSI codes without checking mode
- ❌ Never assume terminal capabilities without checking mode

### Testing Requirements

**Unit Tests** (Per Component):
- Test interactive mode behavior (use `DOC_DOC_INTERACTIVE=true`)
- Test non-interactive mode behavior (use `DOC_DOC_INTERACTIVE=false`)
- Test mode detection in various contexts (redirects, pipes, background)

**Integration Tests**:
- End-to-end test with real terminal attachment
- End-to-end test with output redirection
- End-to-end test with input piping
- Cron job simulation test (no terminal)

**CI/CD Tests**:
- All tests run in non-interactive mode by default
- Separate test suite for interactive feature validation

---

## Architectural Concerns and Risks

### Concern 1: Component Coordination Complexity
**Issue**: Every user-facing component must correctly check mode before behavior  
**Risk**: Components bypass mode check and create blocking operations in non-interactive mode  
**Mitigation**:
- Establish clear code review checklist
- Create linting rule to detect blocking operations (`read -p` without mode check)
- Document pattern clearly in developer guidelines
- Comprehensive test coverage in both modes

**Severity**: HIGH (hangs in automation)  
**Likelihood**: MEDIUM (developers may forget)  
**Overall Risk**: MEDIUM-HIGH

### Concern 2: Terminal Compatibility
**Issue**: ANSI escape codes may not work in all terminal emulators  
**Risk**: Progress display renders incorrectly or corrupts output  
**Mitigation**:
- Test on common terminals (bash, zsh, xterm, gnome-terminal, iTerm2)
- Graceful degradation if terminal width detection fails
- Document supported terminals
- Progress display only activates in interactive mode (limited scope)

**Severity**: LOW (display issue, not functional failure)  
**Likelihood**: LOW (ANSI codes widely supported)  
**Overall Risk**: LOW

### Concern 3: Mode Classification Edge Cases
**Issue**: SSH sessions, tmux/screen, IDE terminals may classify incorrectly  
**Risk**: Wrong mode chosen, poor UX or automation failure  
**Mitigation**:
- POSIX `-t` test is generally reliable
- Environment variable override provides escape hatch: `DOC_DOC_INTERACTIVE=true`
- Document edge cases and override usage
- Test in common environments (SSH with/without PTY, tmux, VS Code terminal)

**Severity**: MEDIUM (affects UX)  
**Likelihood**: LOW (POSIX test accurate for most cases)  
**Overall Risk**: LOW-MEDIUM

### Concern 4: Logging Format Breaking Changes
**Issue**: Structured logging format may break existing log parsing scripts  
**Risk**: User scripts fail after upgrade  
**Mitigation**:
- This is architecture vision, not yet implemented (no breaking change yet)
- Document format change in release notes when implemented
- Consider version flag for log format if needed
- Non-interactive mode is new feature, minimal existing usage

**Severity**: MEDIUM (user script breakage)  
**Likelihood**: LOW (feature not yet released)  
**Overall Risk**: LOW

---

## Compliance with Architectural Constraints

**Technical Constraints Review**:
- ✅ **TC-0001 (Bash Runtime)**: Mode detection uses POSIX sh constructs, fully compatible
- ✅ **No Network Access**: Mode detection is local terminal test, no network required
- ✅ **Platform Support**: POSIX `-t` operator works on Linux, macOS, BSD, WSL
- ✅ **Minimal Dependencies**: No new external dependencies, uses shell built-ins

**Architecture Decision Compliance**:
- ✅ **ADR-0001 (Bash)**: Implementation uses pure Bash
- ✅ **ADR-0007 (Modular Architecture)**: New components follow established pattern
- ✅ **No conflicts** with existing ADRs

---

## Recommendations for Feature Implementation

### Feature 0016 (Mode Detection) - APPROVE
- ✅ **Architecture**: Clean, foundational component with clear responsibility
- ✅ **Dependencies**: No dependencies, can be implemented independently
- ✅ **Integration**: Clear integration points documented
- ⚠️ **Risk**: Must be initialized before any user-facing output (strict ordering)
- **Recommendation**: Implement first, high priority

### Feature 0017 (Interactive Progress Display) - APPROVE WITH CONDITIONS
- ✅ **Architecture**: Well-scoped UI component
- ⚠️ **Terminal Compatibility**: Test across terminal emulators
- ⚠️ **Complexity**: ANSI escape codes require careful implementation
- **Conditions**:
  - Test on: bash, zsh, xterm, gnome-terminal, iTerm2, tmux, screen
  - Implement graceful degradation for unknown terminals
  - Document supported terminals
- **Recommendation**: Implement after mode detection, medium priority

### Feature 0018 (User Prompt System) - APPROVE
- ✅ **Architecture**: Clean abstraction for user interactions
- ✅ **Integration**: Clear usage pattern for other components
- ✅ **Fail-Safe**: Default behavior in non-interactive mode well-defined
- ⚠️ **Prompts**: Must validate all existing prompt locations use this system
- **Recommendation**: Implement after mode detection, high priority

### Feature 0019 (Structured Logging) - APPROVE WITH GUIDANCE
- ✅ **Architecture**: Enhances existing component, maintains backward compatibility
- ⚠️ **Breaking Change**: New format may affect log parsing
- ⚠️ **Migration**: Existing log calls need component tags added
- **Guidance**:
  - Keep backward-compatible log() signature
  - Add structured format as new code path (not replacement)
  - Document component tag standards
  - Update existing calls incrementally
- **Recommendation**: Implement after mode detection, high priority

---

## Architectural Guidelines for Implementation

### 1. Component Loading Order
```bash
# doc.doc.sh - Updated component loading order

# Core components (no dependencies)
source_component "core/constants.sh"
source_component "core/mode_detection.sh"      # NEW: Load before logging
source_component "core/logging.sh"              # ENHANCED: Uses IS_INTERACTIVE
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI components (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
source_component "ui/argument_parser.sh"
source_component "ui/progress_display.sh"       # NEW: Depends on mode detection
source_component "ui/prompt_system.sh"          # NEW: Depends on mode detection

# ... rest of components ...
```

### 2. Mode Check Pattern (Use Everywhere)
```bash
# CORRECT: Check mode before behavior
if [[ "${IS_INTERACTIVE}" == "true" ]]; then
  # Interactive: rich UX
  show_progress "${current}" "${total}"
  prompt_yes_no "Install tool?" "n"
else
  # Non-interactive: automated
  log "INFO" "SCAN" "Progress: ${current}/${total}"
  # Use default, no prompt
fi
```

### 3. Component Tag Standards
```
INIT       - Initialization and startup
SCAN       - Directory scanning and file discovery
PLUGIN     - Plugin loading and execution
TOOL       - Tool verification and installation
WORKSPACE  - Workspace operations
TEMPLATE   - Template processing
REPORT     - Report generation
MAIN       - Main orchestration
```

### 4. Testing Pattern
```bash
# Test both modes for every feature
test_feature_interactive() {
  export DOC_DOC_INTERACTIVE=true
  # Test interactive behavior
}

test_feature_non_interactive() {
  export DOC_DOC_INTERACTIVE=false
  # Test non-interactive behavior
}
```

---

## Success Criteria

Implementation is successful when:

1. ✅ **Mode Detection**: `IS_INTERACTIVE` correctly classified in 100% of test scenarios
2. ✅ **No Hangs**: Zero blocking operations in non-interactive mode (cron job tests pass)
3. ✅ **Progress Visibility**: Interactive users see live progress in all long-running operations
4. ✅ **Structured Logs**: Non-interactive mode produces parseable logs with timestamps and component tags
5. ✅ **No Prompts in Automation**: All prompts suppressed in non-interactive mode, defaults applied
6. ✅ **Test Coverage**: Both modes tested for all user-facing components (>90% coverage)
7. ✅ **Documentation**: Mode-aware behavior documented in architecture and user guides
8. ✅ **Quality Goal R1**: Cron job execution succeeds 100% over 30-day test period

---

## Conclusion

The four features introduce a well-architected, industry-standard solution to enable dual-context operation. The architecture vision has been updated to reflect this significant cross-cutting concern. Implementation should follow the prioritized order, with strict attention to the architectural guidelines to ensure consistency and avoid the primary risk (blocking in non-interactive mode).

**Overall Assessment**: APPROVE - Architecture changes are sound, well-documented, and aligned with quality goals.

**Next Steps**:
1. Developer implements features in priority order (0016 → 0019 → 0017 → 0018)
2. Architect reviews implementation for compliance after each component
3. Comprehensive testing in both modes before merge
4. Update user-facing documentation to describe mode behavior

---

**Review Status**: COMPLETE  
**Architecture Vision**: UPDATED  
**Implementation Ready**: YES
