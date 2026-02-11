# Implementation Decision Records (IDRs)

**Status**: Active  
**Last Updated**: 2026-02-10  
**Vision Reference**: [Architecture Decisions (ADRs)](../../../01_vision/03_architecture/09_architecture_decisions/09_architecture_decisions.md)

## Overview

This directory contains Implementation Decision Records (IDRs) documenting key implementation decisions made during the development of doc.doc.sh. Each IDR captures a single decision with its context, rationale, alternatives considered, and impact.

**Important**: IDRs are separate from ADRs (Architecture Decision Records). ADRs (0001-0007) define strategic architectural decisions in the vision directory, while IDRs document implementation-level decisions made during development.

**Total IDRs**: 17 (IDR-0001 through IDR-0017)

## Table of Contents

- [IDR Index](#idr-index)
- [ADR vs IDR Distinction](#adr-vs-idr-distinction)
- [IDR Format](#idr-format)
- [Status Indicators](#status-indicators)
- [Summary](#summary)

## IDR Index

### IDR-0001: Modular Function Architecture
**File**: [IDR_0001_modular_function_architecture.md](./IDR_0001_modular_function_architecture.md)  
**Decision**: Organize script into focused, single-responsibility functions within a single file for improved testability and maintainability.

### IDR-0002: Exit Code System (0-5)
**File**: [IDR_0002_exit_code_system.md](./IDR_0002_exit_code_system.md)  
**Decision**: Define six exit codes (0-5) as named constants representing specific failure categories for improved scriptability.

### IDR-0003: Pipe-Delimited Internal Data Format for Plugin Data
**File**: [IDR_0003_pipe_delimited_plugin_data.md](./IDR_0003_pipe_delimited_plugin_data.md)  
**Decision**: Use pipe-delimited strings (`"name|description|active"`) for internal plugin data exchange between functions for Bash-native efficiency.

### IDR-0004: Dual JSON Parser Strategy (jq + python3 Fallback)
**File**: [IDR_0004_dual_json_parser.md](./IDR_0004_dual_json_parser.md)  
**Decision**: Implement dual JSON parser strategy—jq as primary parser with python3 fallback—to ensure broad compatibility while maintaining optimal performance.

### IDR-0005: Platform-Specific Plugin Precedence
**File**: [IDR_0005_platform_plugin_precedence.md](./IDR_0005_platform_plugin_precedence.md)  
**Decision**: Platform-specific plugins take precedence over cross-platform plugins when duplicate names exist, enabling platform optimizations and customization.

### IDR-0006: Description Truncation at 80 Characters
**File**: [IDR_0006_description_truncation.md](./IDR_0006_description_truncation.md)  
**Decision**: Truncate plugin descriptions exceeding 80 characters to maintain terminal compatibility and visual consistency across standard terminals.

### IDR-0007: Continue on Malformed Plugin Descriptors
**File**: [IDR_0007_continue_on_malformed_descriptors.md](./IDR_0007_continue_on_malformed_descriptors.md)  
**Decision**: Log warnings and skip malformed plugins during discovery, continuing to process remaining valid plugins for robust error handling.

### IDR-0008: Alphabetical Sorting of Plugin List
**File**: [IDR_0008_alphabetical_plugin_sorting.md](./IDR_0008_alphabetical_plugin_sorting.md)  
**Decision**: Sort plugins alphabetically by name before displaying to provide predictable, scannable output for users.

### IDR-0009: Platform Detection Fallback Strategy
**File**: [IDR_0009_platform_detection_fallback.md](./IDR_0009_platform_detection_fallback.md)  
**Decision**: Implement three-tier platform detection (/etc/os-release → uname -s → "generic") to ensure portability across all POSIX systems.

### IDR-0010: Log Level Design (INFO, WARN, ERROR, DEBUG)
**File**: [IDR_0010_log_level_design.md](./IDR_0010_log_level_design.md)  
**Decision**: Implement four log levels with conditional display—DEBUG/INFO shown only in verbose mode, WARN/ERROR always shown.

### IDR-0011: No Arguments Shows Help (Not Error)
**File**: [IDR_0011_no_args_shows_help.md](./IDR_0011_no_args_shows_help.md)  
**Decision**: Display help and exit with code 0 when script is called without arguments, improving discoverability for new users.

### IDR-0012: Bash Strict Mode (set -euo pipefail)
**File**: [IDR_0012_bash_strict_mode.md](./IDR_0012_bash_strict_mode.md)  
**Decision**: Enable Bash strict mode (`set -euo pipefail`) at script initialization to prevent silent failures and catch errors early.

### IDR-0013: Entry Point Guard for Sourcing
**File**: [IDR_0013_entry_point_guard.md](./IDR_0013_entry_point_guard.md)  
**Decision**: Use entry point guard pattern to prevent `main()` execution when script is sourced, enabling unit testing of individual functions.

### IDR-0014: Modular Component Architecture Implementation
**File**: [IDR_0014_modular_component_architecture_implementation.md](./IDR_0014_modular_component_architecture_implementation.md)  
**Decision**: Implement modular component architecture with 16 components across 4 domains (core, ui, plugin, orchestration), transforming the 509-line monolithic script into a maintainable, testable component-based system with an 83-line entry script.

### IDR-0015: Workspace Management Implementation
**File**: [IDR_0015_workspace_management_implementation.md](./IDR_0015_workspace_management_implementation.md)  
**Decision**: Implement workspace management system with content-based SHA-256 hashing, JSON state persistence, and corruption recovery for the plugin execution pipeline.

### IDR-0016: Plugin Execution Engine Implementation
**File**: [IDR_0016_plugin_execution_engine_implementation.md](./IDR_0016_plugin_execution_engine_implementation.md)  
**Decision**: Implement plugin execution engine with Kahn's algorithm for dependency ordering, Bubblewrap sandbox with graceful fallback, and layered validation architecture.

### IDR-0017: Mode-Aware UI Components
**File**: [IDR_0017_mode_aware_ui_components.md](./IDR_0017_mode_aware_ui_components.md)  
**Decision**: Implement three mode-aware UI components (progress display, prompt system, structured logging) as separate components following the modular architecture pattern, enabling interactive directory scan with progress indication and non-interactive structured logging.

## ADR vs IDR Distinction

**Architecture Decision Records (ADRs)**:
- Located in `01_vision/03_architecture/09_architecture_decisions/`
- Document strategic architectural decisions during planning/design phase
- ADR-0001 through ADR-0007
- Define the "what" and "why" of the system architecture

**Implementation Decision Records (IDRs)**:
- Located in `03_documentation/01_architecture/09_architecture_decisions/` (this directory)
- Document implementation-level decisions made during development
- IDR-0001 through IDR-0017
- Define the "how" and implementation details
- Must document any deviations from vision ADRs
- Must create risk records for deviations

**Conversion History** (2026-02-08):
All previous ADRs in documentation (ADR-0007, 0008, 0010-0020) were converted to IDRs (IDR-0001 through IDR-0013) to properly distinguish architecture decisions from implementation decisions.

## IDR Format

Each IDR follows this structure:
- **Title**: Clear, descriptive decision title with IDR number
- **Metadata**: Status, date, context, related ADRs
- **Decision**: Concise statement of what was decided
- **Context**: Background and problem being addressed
- **Reason**: Why this decision was necessary
- **Deviation from Vision**: Documentation of any deviations from ADRs (required)
- **Associated Risks**: Risk records for deviations (required if deviation exists)
- **Rationale**: Why this decision was made
- **Alternatives Considered**: Other options evaluated
- **Consequences**: Positive, negative, and risks
- **Implementation Notes**: Technical details and guidance
- **Related Items**: Links to ADRs, requirements, constraints, features

## Status Indicators

- ✅ **Accepted**: Decision approved and implemented
- 🔄 **Proposed**: Decision proposed but not yet implemented
- ⚠️ **Deprecated**: Decision superseded by newer IDR
- ❌ **Rejected**: Decision considered but not adopted

## Summary

All implementation decisions align with vision principles (ADRs):
- **Unix Philosophy**: Clean interface, composability, scriptability
- **Lightweight**: Minimal dependencies, efficient data structures
- **Robustness**: Fail-fast error handling, comprehensive validation
- **Testability**: Modular design, sourceable functions, clear interfaces

For strategic architecture decisions, see [Vision ADRs](../../../01_vision/03_architecture/09_architecture_decisions/09_architecture_decisions.md).
