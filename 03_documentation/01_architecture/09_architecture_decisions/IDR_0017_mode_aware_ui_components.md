# IDR-0017: Mode-Aware UI Components Implementation

**ID**: IDR-0017  
**Status**: Accepted  
**Created**: 2026-02-11  
**Features**: Feature 0017 (Interactive Progress Display), Feature 0018 (User Prompt System), Feature 0019 (Structured Logging)  
**Related ADRs**: [ADR-0007](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md), [ADR-0008](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0008_posix_terminal_test_for_mode_detection.md)

## Table of Contents

- [Context](#context)
- [Implementation Decisions](#implementation-decisions)
- [Consequences](#consequences)
- [Compliance Verification](#compliance-verification)
- [Related Items](#related-items)

## Context

With mode detection (feature_0016) implemented in `scripts/components/core/mode_detection.sh`, the system can distinguish interactive from non-interactive execution contexts. Three features now build on this foundation to deliver user-facing behavior that adapts to the detected mode:

- **Feature 0017** (Interactive Progress Display): Live progress bar with file counters and in-place terminal updates during directory scanning and plugin execution.
- **Feature 0018** (User Prompt System): Yes/no prompts for user confirmations (tool installation, directory creation) that auto-default in non-interactive mode.
- **Feature 0019** (Structured Logging): Dual-mode log formatting with ISO 8601 timestamps and component tags in non-interactive mode, and concise human-friendly output in interactive mode.

These three components collectively enable the interactive directory scan workflow: the scanner (feature_0006) discovers files, the plugin executor (feature_0009) runs the stat plugin (feature_0020) against each file, and the UI components provide real-time progress feedback, user control over optional operations, and structured audit trails for automated environments.

Without these components, the system provides no visual feedback during long-running scans, blocks indefinitely on prompts in automated contexts, and produces unstructured log output unsuitable for monitoring or log aggregation.

## Implementation Decisions

### 1. Three Separate Components Following Domain Architecture

**Decision**: Implement progress display and prompt system as two new components in the `ui/` domain, and enhance the existing `core/logging.sh` component for structured logging. Do not merge these concerns into a single component.

**Rationale**:
- Follows the 4-domain organization established in IDR-0014 (core, ui, plugin, orchestration)
- Each component has a distinct responsibility and distinct callers
- Progress display is called by orchestration components during long-running loops
- Prompt system is called by plugin and workspace components for user decisions
- Logging is a cross-cutting concern used by all components
- Separate components enable independent testing of each behavior
- Aligns with the component size guideline (< 200 lines per component) from ADR-0007

**Alternatives Considered**:
- Single `ui/mode_aware_output.sh` combining all three → Rejected (violates single responsibility, would exceed size guideline)
- Logging changes as a new component instead of enhancement → Rejected (would break existing `log()` callers; backward compatibility requires in-place enhancement)

### 2. Component File Locations and Interfaces

**Decision**: Place components in the established directory structure with standardized interfaces.

#### 2.1 Progress Display Component

**Location**: `scripts/components/ui/progress_display.sh`

**Interface**:
```bash
# Component: progress_display.sh
# Purpose: Live in-place progress rendering for interactive mode
# Dependencies: mode_detection.sh, logging.sh
# Exports: show_progress(), clear_progress(), render_progress_bar()
# Side Effects: Writes to stdout (interactive), no output (non-interactive)

show_progress()        # (percent, processed, total, skipped, current_file, current_plugin)
clear_progress()       # Clears progress display and moves cursor to clean state
render_progress_bar()  # (percent) → renders 40-char bar with centered percentage
```

**Behavior by Mode**:
| Function | Interactive | Non-Interactive |
|----------|------------|-----------------|
| `show_progress()` | Renders multi-line in-place display | Returns immediately (no-op) |
| `clear_progress()` | Clears ANSI display, moves cursor | Returns immediately (no-op) |
| `render_progress_bar()` | Renders `████░░░░ 42%` bar | Returns immediately (no-op) |

#### 2.2 Prompt System Component

**Location**: `scripts/components/ui/prompt_system.sh`

**Interface**:
```bash
# Component: prompt_system.sh
# Purpose: User prompts with mode-aware behavior
# Dependencies: mode_detection.sh, logging.sh
# Exports: prompt_yes_no(), prompt_tool_installation()
# Side Effects: Reads from stdin (interactive), no I/O (non-interactive)

prompt_yes_no()              # (message, default) → return 0=yes, 1=no
prompt_tool_installation()   # (tool_name, install_command) → return 0=installed, 1=declined
```

**Behavior by Mode**:
| Function | Interactive | Non-Interactive |
|----------|------------|-----------------|
| `prompt_yes_no()` | Shows prompt, reads user input | Returns default immediately |
| `prompt_tool_installation()` | Prompts user, runs install if approved | Logs auto-decline, returns 1 |

#### 2.3 Logging Enhancement

**Location**: `scripts/components/core/logging.sh` (existing component, enhanced)

**Enhanced Interface**:
```bash
# Component: logging.sh
# Purpose: Logging infrastructure with mode-aware formatting and component tags
# Dependencies: constants.sh, mode_detection.sh
# Exports: log(), set_log_level(), is_verbose(), log_structured(), log_interactive(), log_progress_milestone()
# Side Effects: Writes to stderr

log()                    # (level, [component], message) — backward-compatible signature
log_structured()         # (level, component, message) — structured format for non-interactive
log_interactive()        # (level, message) — human-friendly format for interactive
log_progress_milestone() # (processed, total) — milestone logging for non-interactive
```

**Behavior by Mode**:
| Function | Interactive | Non-Interactive |
|----------|------------|-----------------|
| `log()` | Delegates to `log_interactive()` | Delegates to `log_structured()` |
| `log_interactive()` | `[ERROR] msg` with ANSI colors | N/A (not called) |
| `log_structured()` | N/A (not called) | `[2026-02-10T14:30:00Z] [INFO] [SCAN    ] msg` |
| `log_progress_milestone()` | No-op (progress display used instead) | Logs every 10% or 50 files |

### 3. Backward-Compatible log() Signature

**Decision**: Maintain the existing 2-argument `log(level, message)` signature while supporting the new 3-argument `log(level, component, message)` form.

**Rationale**:
- Existing callers throughout the codebase use `log "INFO" "message"` (2-argument form)
- Changing all existing callers simultaneously is high-risk and high-effort
- The 3-argument form auto-detects via argument count: if `$3` is empty, treat `$2` as message with component defaulting to `MAIN`
- Enables incremental migration of existing log calls to include component tags
- Zero breaking changes to existing code

**Pattern**:
```bash
log() {
  local level="$1"
  local component="${2:-MAIN}"
  local message="$3"

  # Backward compatibility: if only 2 args, $2 is the message
  if [[ -z "$message" ]]; then
    message="$component"
    component="MAIN"
  fi
  # ... format based on IS_INTERACTIVE ...
}
```

### 4. 40-Character Progress Bar with Centered Percentage

**Decision**: Use a fixed 40-character progress bar width with filled (`█`) and empty (`░`) Unicode block characters, and center the percentage text within the bar.

**Rationale**:
- 40 characters fits within 80-column minimum terminal width with room for label text
- Unicode block characters provide clear visual distinction between filled and empty regions
- Centered percentage is immediately readable without scanning to end of line
- Fixed width ensures consistent rendering regardless of terminal width
- Integer arithmetic only (`filled = percent * 40 / 100`) avoids floating-point dependency

**Alternatives Considered**:
- ASCII characters (`#` and `-`) → Rejected (less visually distinct, less professional appearance)
- Variable-width bar based on terminal width → Rejected (adds complexity, inconsistent visual experience)
- Percentage at end of bar → Rejected (less readable for long bars)

### 5. Multi-Line In-Place Display with ANSI Cursor Control

**Decision**: Use ANSI escape sequences for in-place multi-line progress display: `\r` (carriage return), `\033[K` (clear line), and `\033[nA` (cursor up n lines).

**Rationale**:
- In-place updates prevent log scrolling during progress display
- Multi-line display shows progress bar, file counters, current file, and current plugin simultaneously
- ANSI escape sequences are widely supported across modern terminal emulators
- Only emitted when `IS_INTERACTIVE=true`, ensuring clean output in non-interactive mode
- Graceful degradation: if terminal doesn't support ANSI, output is garbled but functional (not a crash)

**Display Layout** (5 lines, updated in place):
```
Progress: [████████████████░░░░░░░░░░░░░░░░░░░░░░░░] 42%
Files processed: 64/152
Files skipped: 3
Processing: documents/reports/quarterly_review_2025.pdf
Executing plugin: stat
```

### 6. Terminal Width Detection with 80-Column Fallback

**Decision**: Detect terminal width via `tput cols` with a fallback to 80 columns if detection fails.

**Rationale**:
- `tput cols` is POSIX-standard and available on all target platforms
- 80 columns is the universal minimum terminal width standard
- Width used to truncate file paths that would cause line wrapping
- Width cached per invocation (terminal resize during execution is an accepted edge case)
- Only queried in interactive mode; non-interactive mode has no terminal width concept

### 7. Prompt Retry Limit of 3 Attempts

**Decision**: Allow maximum 3 invalid prompt responses before falling back to the default answer.

**Rationale**:
- Prevents infinite loops from accidental keypresses or script injection
- 3 attempts provides reasonable opportunity for user correction
- Default answer used after exhaustion, logged at WARN level for auditability
- Aligns with common CLI tool behavior (apt, pip, npm all limit retries)

### 8. Test Override via Environment Variable

**Decision**: Support `DOC_DOC_PROMPT_RESPONSE` environment variable to override prompt responses in test environments.

**Rationale**:
- Unit tests cannot provide interactive stdin input
- Environment variable provides deterministic test control
- Follows established pattern: `DOC_DOC_INTERACTIVE` already overrides mode detection
- Checked before interactive prompt loop, does not affect non-interactive default behavior
- Enables testing of both "user says yes" and "user says no" code paths

### 9. Component Tag Standards (Fixed Set)

**Decision**: Define 8 standardized component tags for structured logging, with fixed-width formatting (8 characters, right-padded).

**Tags**:
| Tag | Usage |
|-----|-------|
| `INIT` | Initialization, startup, mode detection |
| `SCAN` | Directory scanning, file discovery |
| `PLUGIN` | Plugin loading, execution, output parsing |
| `TOOL` | Tool verification, installation |
| `WORKSPACE` | Workspace operations |
| `TEMPLATE` | Template processing |
| `REPORT` | Report generation |
| `MAIN` | Main orchestration, general operations |

**Rationale**:
- Fixed set ensures consistent log output across all components
- 8-character width aligns log columns for readability and parsing
- Tags map directly to the component domains (core maps to INIT/MAIN, ui to MAIN, plugin to PLUGIN/TOOL, orchestration to SCAN/WORKSPACE/TEMPLATE/REPORT)
- Tags are grepping-friendly: `grep '\[PLUGIN\]' log.txt` filters to plugin activity
- New tags may be added as the system grows, but existing tags must not change

### 10. Milestone-Based Progress Logging for Non-Interactive Mode

**Decision**: In non-interactive mode, log progress milestones every 10% completion or every 50 files (whichever comes first), instead of per-file logging.

**Rationale**:
- Per-file logging produces excessive output for large directory scans (thousands of lines)
- Milestone logging provides sufficient granularity for monitoring and alerting
- 10% intervals map to meaningful progress checkpoints
- 50-file intervals prevent long silences when processing large file sets with few percentage changes
- Start and end events always logged regardless of milestone interval
- Compatible with log aggregation systems that expect periodic heartbeat entries

### 11. Integration Points with Scanner and Plugin Executor

**Decision**: Progress display is called by the orchestration layer (scanner/executor loop), not by individual plugins or components.

**Rationale**:
- The scanner loop has access to total file count and current position (needed for percentage)
- Individual plugins should not manage UI state (separation of concerns)
- Single integration point reduces coupling and simplifies testing
- The orchestration layer already coordinates scanner → plugin executor flow
- Progress display and milestone logging share the same integration point, switching on `IS_INTERACTIVE`

**Integration Pattern**:
```bash
# In orchestration loop (scanner/executor)
for file in "${files[@]}"; do
  percent=$(( processed * 100 / total ))

  if [[ "${IS_INTERACTIVE}" == "true" ]]; then
    show_progress "${percent}" "${processed}" "${total}" "${skipped}" "${file}" "${plugin_name}"
  else
    log_progress_milestone "${processed}" "${total}"
  fi

  # Execute plugin on file...
  ((processed++))
done

clear_progress
```

### 12. Component Loading Order Update

**Decision**: Insert new UI components into the existing loading order after the current UI components and after mode detection.

**Updated Loading Order**:
```bash
# Core components (no dependencies)
source_component "core/constants.sh"
source_component "core/mode_detection.sh"       # Foundation for all mode-aware components
source_component "core/logging.sh"              # Enhanced: uses IS_INTERACTIVE
source_component "core/error_handling.sh"
source_component "core/platform_detection.sh"

# UI components (depend on core)
source_component "ui/help_system.sh"
source_component "ui/version_info.sh"
source_component "ui/argument_parser.sh"
source_component "ui/progress_display.sh"       # NEW: depends on mode_detection, logging
source_component "ui/prompt_system.sh"          # NEW: depends on mode_detection, logging

# Plugin & Orchestration components (unchanged)
# ...
```

**Rationale**:
- Mode detection must load before logging (logging uses `IS_INTERACTIVE`)
- Logging must load before progress display and prompt system (both log their actions)
- UI components load before orchestration components that call them
- Maintains the existing 3-phase loading pattern from IDR-0014

## Consequences

### Positive Outcomes

✅ **Dual-Mode Operation**: System serves both interactive users (rich UX) and automated environments (structured logs) with a single codebase  
✅ **Modularity**: Three focused components, each independently testable and under 200-line target  
✅ **Backward Compatibility**: Existing `log()` callers continue working without modification  
✅ **User Control**: Interactive users can approve or decline optional operations; automated runs use safe defaults  
✅ **Observability**: Non-interactive mode produces structured, parseable logs suitable for monitoring and alerting  
✅ **Professional UX**: Progress bar with file counters provides real-time feedback during long scans  
✅ **Safety**: Prompts auto-default in non-interactive mode, preventing hangs in cron jobs and CI/CD pipelines  
✅ **Testability**: Environment variable overrides (`DOC_DOC_INTERACTIVE`, `DOC_DOC_PROMPT_RESPONSE`) enable deterministic testing  

### Trade-offs Accepted

📊 **ANSI Dependency**: Progress display relies on ANSI escape sequences, which may render incorrectly in rare terminal emulators (mitigated: interactive-only, graceful degradation)  
📊 **Component Count**: Two new components increase the total from 16 to 18 (acceptable given clear single-responsibility scope)  
📊 **Logging Migration**: Existing log calls default to `MAIN` component tag; full tag coverage requires incremental migration of callers (low risk, backward compatible)  
📊 **Fixed Progress Bar Width**: 40-character bar does not adapt to wide terminals (simplicity trade-off; consistent rendering preferred over adaptive width)  

## Compliance Verification

### Against ADR-0007 (Modular Component Architecture)

| ADR-0007 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| Components in `scripts/components/` | ✅ Planned | `ui/progress_display.sh`, `ui/prompt_system.sh`, `core/logging.sh` |
| Component interface headers | ✅ Planned | Standard headers with dependencies and exports |
| Explicit dependency loading | ✅ Planned | Loading order updated in entry script |
| Component independence | ✅ Planned | Each component independently testable |
| Component size < 200 lines | ✅ Expected | Each new component scoped to single responsibility |
| No cross-dependencies | ✅ Planned | UI components depend on core only, not on each other |

### Against ADR-0008 (POSIX Terminal Test for Mode Detection)

| ADR-0008 Specification | Implementation Status | Notes |
|------------------------|----------------------|-------|
| Mode detection via `[ -t 0 ] && [ -t 1 ]` | ✅ Implemented | feature_0016 complete in `core/mode_detection.sh` |
| `IS_INTERACTIVE` global variable | ✅ Implemented | Used by all three new components |
| `DOC_DOC_INTERACTIVE` override | ✅ Implemented | Enables testing in both modes |
| No ANSI codes in non-interactive | ✅ Planned | Progress display and colored logs gated on `IS_INTERACTIVE` |
| No blocking prompts in non-interactive | ✅ Planned | Prompt system returns default immediately |

### Against req_0057 (Interactive Mode Behavior)

| Requirement | Implementation Status | Notes |
|-------------|----------------------|-------|
| Live progress display | ✅ Planned | `ui/progress_display.sh` with progress bar and counters |
| User prompts for confirmations | ✅ Planned | `ui/prompt_system.sh` with yes/no and tool installation |
| Rich terminal output | ✅ Planned | ANSI colors, Unicode progress bar, in-place updates |

### Against req_0058 (Non-Interactive Mode Behavior)

| Requirement | Implementation Status | Notes |
|-------------|----------------------|-------|
| Structured log format | ✅ Planned | `[timestamp] [level] [component] message` |
| No blocking operations | ✅ Planned | Prompts auto-default, progress display suppressed |
| Machine-parseable output | ✅ Planned | ISO 8601 timestamps, fixed-width component tags |
| Milestone progress logging | ✅ Planned | Every 10% or 50 files |

## Related Items

- **Vision ADRs**: [ADR-0007: Modular Component Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md), [ADR-0008: POSIX Terminal Test](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0008_posix_terminal_test_for_mode_detection.md)
- **Architecture Review**: [Mode-Aware Features Review](../../../01_vision/03_architecture/ARCH_REVIEW_MODE_AWARE_FEATURES.md)
- **Features**: [Feature 0017](../../../02_agile_board/05_implementing/feature_0017_interactive_progress_display.md), [Feature 0018](../../../02_agile_board/05_implementing/feature_0018_user_prompt_system.md), [Feature 0019](../../../02_agile_board/05_implementing/feature_0019_structured_logging.md)
- **Requirements**: [req_0057: Interactive Mode Behavior](../../../01_vision/02_requirements/03_accepted/req_0057_interactive_mode_behavior.md), [req_0058: Non-Interactive Mode Behavior](../../../01_vision/02_requirements/03_accepted/req_0058_non_interactive_mode_behavior.md)
- **Foundation**: [IDR-0014: Modular Component Architecture](IDR_0014_modular_component_architecture_implementation.md), [IDR-0016: Plugin Execution Engine](IDR_0016_plugin_execution_engine_implementation.md)
- **Existing Components**: `scripts/components/core/mode_detection.sh`, `scripts/components/core/logging.sh`, `scripts/components/orchestration/scanner.sh`, `scripts/components/plugin/plugin_executor.sh`

## Deviation from Vision

No deviation from architecture vision. This decision implements the mode-aware behavior pattern exactly as specified in ADR-0008 and the architecture review document. The component organization follows ADR-0007's established domain structure. The only implementation-level addition is the backward-compatible 2/3-argument `log()` signature, which is a pragmatic enhancement not anticipated in the vision but fully compatible with it.

## Associated Risks

No new risks introduced beyond those already documented in the [Architecture Review](../../../01_vision/03_architecture/ARCH_REVIEW_MODE_AWARE_FEATURES.md):

- **Concern 1 (Component Coordination)**: Mitigated by clear mode-check pattern and environment variable overrides for testing
- **Concern 2 (Terminal Compatibility)**: Mitigated by interactive-only ANSI output and graceful degradation
- **Concern 3 (Mode Classification Edge Cases)**: Mitigated by `DOC_DOC_INTERACTIVE` override
- **Concern 4 (Logging Format)**: Mitigated by backward-compatible `log()` signature
