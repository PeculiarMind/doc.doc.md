# Architecture Decision Records (ADRs)

**Feature**: Feature 0001 - Basic Script Structure  
**Implementation Date**: 2026-02-06  
**Status**: Implemented  
**Vision Reference**: [Architecture Decisions](../../../01_vision/03_architecture/09_architecture_decisions/09_architecture_decisions.md)

## Overview

This directory contains Architecture Decision Records (ADRs) documenting key architectural decisions made during the implementation of doc.doc.sh. Each ADR captures a single decision with its context, rationale, alternatives considered, and impact.

## ADR Index

### ADR-0001: Use "Usage" Instead of "USAGE" in Help Text
**File**: [adr_0001_usage_sentence_case.md](./adr_0001_usage_sentence_case.md)  
**Decision**: Use sentence case ("Usage:") instead of all caps ("USAGE:") in help text headers for improved user-friendliness and modern CLI consistency.

### ADR-0002: Guide Users with "Try --help" on Errors
**File**: [adr_0002_help_guidance_on_errors.md](./adr_0002_help_guidance_on_errors.md)  
**Decision**: Include `Try 'doc.doc.sh --help' for more information` guidance in all argument-related error messages to improve user experience.

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

All nine decisions align with vision principles:
- **Unix Philosophy**: Clean interface, composability (AD-0002, AD-0008)
- **Lightweight**: Minimal dependencies (AD-0003)
- **Quality**: Error handling, strictness (AD-0004, AD-0006)
- **Extensibility**: Modular architecture (AD-0007)
- **User-Focused**: Discoverability, guidance (AD-0001, AD-0005)

No decisions conflict with architecture vision. All establish patterns consistent with future feature development.

## Historical Reference

The original consolidated decisions file has been archived as `_archived_feature_0001_decisions.md` for historical reference.
