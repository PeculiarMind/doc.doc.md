# Architecture Documentation

This directory contains the **implemented architecture** documentation for the doc.doc.md project following the arc42 template structure.

## Purpose

This documentation reflects the **actual implementation** of the system, maintained in sync with the codebase. It complements the architecture vision in `01_vision/03_architecture/` by documenting what has been built.

## Structure

The documentation follows the arc42 template with the following sections:

- `05_building_block_view/` - Implemented components and their structure
- `06_runtime_view/` - Actual runtime behavior and interactions
- `09_architecture_decisions/` - Implementation decisions made during development
- `99_cross_references/` - Links between vision, requirements, and implementation

## Relationship to Vision

- **Vision** (`01_vision/03_architecture/`) - Planned architecture and design intent
- **Implementation Documentation** (this directory) - Actual implementation details
- **Deviations** are documented in `09_architecture_decisions/` with rationale

## Update Workflow

1. Developer Agent implements features
2. Architect Agent updates this documentation after compliance verification
3. Documentation stays synchronized with implementation
4. Deviations from vision are recorded and justified

## Navigation

Start with `05_building_block_view/` to understand the implemented components, then explore runtime behavior in `06_runtime_view/`.
