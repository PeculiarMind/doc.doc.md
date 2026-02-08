# Architecture Decision Records (ADRs)

**Status**: Active  
**Last Updated**: 2026-02-08  
**Vision Reference**: [Architecture Decisions](../../../01_vision/03_architecture/09_architecture_decisions/09_architecture_decisions.md)

## Overview

This directory contains Architecture Decision Records (ADRs) documenting key architectural decisions made during the implementation of doc.doc.sh. Each ADR captures a single decision with its context, rationale, alternatives considered, and impact.

**Total ADRs**: 13 (ADR-0003 through ADR-0015)

## Table of Contents

- [ADR Index](#adr-index)
- [ADR Format](#adr-format)
- [Status Indicators](#status-indicators)
- [Summary](#summary)
- [Non-Architecture Decisions](#non-architecture-decisions)
- [Historical Reference](#historical-reference)

## ADR Index

### ADR-0003: Platform Detection Fallback Strategy
**File**: [adr_0003_platform_detection_fallback.md](./adr_0003_platform_detection_fallback.md)  
**Decision**: Implement three-tier platform detection (/etc/os-release → uname -s → "generic") to ensure portability across all POSIX systems.

### ADR-0004: Log Level Design (INFO, WARN, ERROR, DEBUG)
**File**: [adr_0004_log_level_design.md](./adr_0004_log_level_design.md)  
**Decision**: Implement four log levels with conditional display—DEBUG/INFO shown only in verbose mode, WARN/ERROR always shown.

### ADR-0005: No Arguments Shows Help (Not Error)
**File**: [adr_0005_no_args_shows_help.md](./adr_0005_no_args_shows_help.md)  
**Decision**: Display help and exit with code 0 when script is called without arguments, improving discoverability for new users.

### ADR-0006: Bash Strict Mode (set -euo pipefail)
**File**: [adr_0006_bash_strict_mode.md](./adr_0006_bash_strict_mode.md)  
**Decision**: Enable Bash strict mode (`set -euo pipefail`) at script initialization to prevent silent failures and catch errors early.

### ADR-0007: Modular Function Architecture
**File**: [adr_0007_modular_function_architecture.md](./adr_0007_modular_function_architecture.md)  
**Decision**: Organize script into focused, single-responsibility functions rather than monolithic code for improved testability and maintainability.

### ADR-0008: Exit Code System (0-5)
**File**: [adr_0008_exit_code_system.md](./adr_0008_exit_code_system.md)  
**Decision**: Define six exit codes (0-5) as named constants representing specific failure categories for improved scriptability.

### ADR-0009: Entry Point Guard for Sourcing
**File**: [adr_0009_entry_point_guard.md](./adr_0009_entry_point_guard.md)  
**Decision**: Use entry point guard pattern to prevent `main()` execution when script is sourced, enabling unit testing of individual functions.

### ADR-0010: Pipe-Delimited Internal Data Format for Plugin Data
**File**: [adr_0010_pipe_delimited_plugin_data.md](./adr_0010_pipe_delimited_plugin_data.md)  
**Decision**: Use pipe-delimited strings (`"name|description|active"`) for internal plugin data exchange between functions for Bash-native efficiency.

### ADR-0011: Dual JSON Parser Strategy (jq + python3 Fallback)
**File**: [adr_0011_dual_json_parser.md](./adr_0011_dual_json_parser.md)  
**Decision**: Implement dual JSON parser strategy—jq as primary parser with python3 fallback—to ensure broad compatibility while maintaining optimal performance.

### ADR-0012: Platform-Specific Plugin Precedence
**File**: [adr_0012_platform_plugin_precedence.md](./adr_0012_platform_plugin_precedence.md)  
**Decision**: Platform-specific plugins take precedence over cross-platform plugins when duplicate names exist, enabling platform optimizations and customization.

### ADR-0013: Description Truncation at 80 Characters
**File**: [adr_0013_description_truncation.md](./adr_0013_description_truncation.md)  
**Decision**: Truncate plugin descriptions exceeding 80 characters to maintain terminal compatibility and visual consistency across standard terminals.

### ADR-0014: Continue on Malformed Plugin Descriptors
**File**: [adr_0014_continue_on_malformed_descriptors.md](./adr_0014_continue_on_malformed_descriptors.md)  
**Decision**: Log warnings and skip malformed plugins during discovery, continuing to process remaining valid plugins for robust error handling.

### ADR-0015: Alphabetical Sorting of Plugin List
**File**: [adr_0015_alphabetical_plugin_sorting.md](./adr_0015_alphabetical_plugin_sorting.md)  
**Decision**: Sort plugins alphabetically by name before displaying to provide predictable, scannable output for users.

## ADR Format

Each ADR follows this structure:
- **Title**: Clear, descriptive decision title with ADR number
- **Metadata**: Status, date, context, feature reference
- **Decision**: Concise statement of what was decided
- **Context**: Background and problem being addressed
- **Rationale**: Why this decision was made
- **Alternatives Considered**: Other options evaluated
- **Implementation**: Technical details (if applicable)
- **Impact**: Effects on the project
- **Related Decisions**: Links to other ADRs (if applicable)

## Status Indicators

- ✅ **Approved**: Decision approved and implemented
- 🔄 **Proposed**: Decision proposed but not yet implemented
- ⚠️ **Deprecated**: Decision superseded by newer ADR
- ❌ **Rejected**: Decision considered but not adopted

## Summary

All architecture decisions align with vision principles:
- **Unix Philosophy**: Clean interface, composability, scriptability
- **Lightweight**: Minimal dependencies, efficient data structures
- **Quality**: Error handling, strictness, robustness
- **Extensibility**: Modular architecture, plugin system
- **User-Focused**: Discoverability, guidance, clear output
- **Portability**: Platform detection, dual parser strategy

No decisions conflict with architecture vision. All establish patterns consistent with future feature development.

## Non-Architecture Decisions

Two decisions originally documented here were determined to be implementation details rather than architecture decisions:
- **Usage Sentence Case**: Moved to feature item as implementation note
- **Help Guidance on Errors**: Moved to feature item as implementation note

These decisions remain valuable but are better documented at the feature level.

## Historical Reference

The original consolidated decisions file has been archived as `_archived_feature_0001_decisions.md` for historical reference.
