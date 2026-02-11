---
title: Architecture Decisions
arc42-chapter: 9
---

# 9. Architecture Decisions

## Table of Contents

- [Overview](#overview)
- [ADR Index](#adr-index)
- [Decision Status Legend](#decision-status-legend)

## Overview

This document provides an index of all Architecture Decision Records (ADRs) for the doc.doc project. Each ADR captures a significant architectural decision, documenting the context, alternatives considered, rationale, and consequences.

**Purpose**: ADRs serve as a historical record of architectural choices, helping current and future team members understand why the system is designed the way it is.

**Structure**: Each ADR is documented in a separate file following the naming pattern ADR_<FOUR_DIGIT_NUMBER>_<title>.md. This overview provides a quick reference to all decisions.

**Important**: ADR IDs are globally unique across the entire project. Vision ADRs (0001-0007) are defined here, while implementation-specific ADRs (0008, 0010-0020) are in `03_documentation/01_architecture/09_architecture_decisions/`. Before assigning a new ADR number, check both locations.
## ADR Index

| ID | Title | Status | Date | Link |
|----|-------|--------|------|------|
| ADR-0001 | Bash as Primary Implementation Language | Accepted | 2026-02-06 | [View](ADR_0001_bash_as_primary_implementation_language.md) |
| ADR-0002 | JSON Workspace for State Persistence | Accepted | 2026-02-06 | [View](ADR_0002_json_workspace_for_state_persistence.md) |
| ADR-0003 | Data-Driven Plugin Orchestration | Accepted | 2026-02-06 | [View](ADR_0003_data_driven_plugin_orchestration.md) |
| ADR-0004 | Platform-Specific Plugin Directories | Accepted | 2026-02-06 | [View](ADR_0004_platform_specific_plugin_directories.md) |
| ADR-0005 | Template-Based Report Generation | Accepted | 2026-02-06 | [View](ADR_0005_template_based_report_generation.md) |
| ADR-0006 | No Agent System in Product Architecture | Accepted | 2026-02-06 | [View](ADR_0006_no_agent_system_in_product_architecture.md) |
| ADR-0007 | Modular Component-Based Script Architecture | Accepted | 2026-02-08 | [View](ADR_0007_modular_component_based_script_architecture.md) |
| ADR-0008 | POSIX Terminal Test for Mode Detection | Accepted | 2026-02-10 | [View](ADR_0008_posix_terminal_test_for_mode_detection.md) |
| ADR-0009 | Plugin Security Sandboxing with Bubblewrap | Accepted | 2026-02-11 | [View](ADR_0009_plugin_security_sandboxing_bubblewrap.md) |
| ADR-0010 | Plugin-Toolkit Interface Architecture | Accepted | 2026-02-11 | [View](ADR_0010_plugin_toolkit_interface_architecture.md) |

## Decision Status Legend

- **Proposed**: Decision under consideration, not yet implemented
- **Accepted**: Decision approved and implemented or in progress
- **Superseded**: Decision replaced by a newer ADR
- **Deprecated**: Decision no longer applicable or relevant
