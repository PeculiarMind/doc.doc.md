---
name: architecture-documentation
description: "Use when: authoring or reviewing architecture documents — Arc42 sections, ADRs, IDRs, DEBTRs, architecture concepts, or architecture reviews. Covers structure, content conventions, and traceability requirements."
---

# Architecture Documentation

This project uses **Arc42** for implementation documentation and a vision-level architecture folder for design-time decisions.

## Folder Structure

| Purpose | Location |
|---------|----------|
| Architecture vision (design-time) | `project_management/02_project_vision/03_architecture_vision/` |
| Architecture implementation docs | `project_documentation/01_architecture/` |
| ADRs (design decisions) | `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_XXXX_*.md` |
| IDRs (implementation decisions) | `project_documentation/01_architecture/09_architecture_decisions/IDR_XXXX_*.md` |
| Technical debt | `project_documentation/01_architecture/11_risks_and_technical_debt/DEBTR_XXXX_*.md` |
| Architecture concepts | `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_XXXX_*.md` |
| Architecture reviews | `project_management/04_reporting/01_architecture_reviews/ARCHREV_XXXX_*.md` |

## Arc42 Section Conventions

Each section in `project_documentation/01_architecture/` maps to an Arc42 chapter:

| # | Section | Content |
|---|---------|---------|
| 01 | Introduction and Goals | Purpose, quality goals, stakeholders |
| 02 | Constraints | Technical, organizational, regulatory limits |
| 03 | System Scope and Context | System boundaries, external interfaces (context diagram) |
| 04 | Solution Strategy | Core technology and design decisions |
| 05 | Building Block View | Component hierarchy and responsibilities |
| 06 | Runtime View | Key processing sequences and flows |
| 07 | Deployment View | Installation, runtime environment |
| 08 | Concepts | Cross-cutting patterns (security, error handling, logging) |
| 09 | Architecture Decisions | ADRs and IDRs |
| 10 | Quality Requirements | Measurable quality scenarios |
| 11 | Risks and Technical Debt | Known risks, DEBTR records |
| 12 | Glossary | Domain terms and definitions |

## ADR Authoring

Use template: `project_management/01_guidelines/documentation_standards/doc_templates/ADR_template.md`

**Required sections:**
- **Status**: Proposed / Accepted / Deprecated / Superseded
- **Context**: What forces are at play? Why is a decision needed?
- **Decision**: What was decided, stated in full.
- **Consequences**: Positive and negative outcomes. What becomes easier or harder?
- **Alternatives considered**: Other options evaluated and why they were rejected.
- **Linked to**: Relevant CRs, solution strategies, other ADRs.

**Numbering**: `ADR_XXXX` — verify the next available ID before creating.

## IDR Authoring

Same structure as ADR but for decisions made *during implementation*, not design.  
Use template: `project_management/01_guidelines/documentation_standards/doc_templates/IDR_template.md`  
**Linked to**: Relevant ADRs, work items, source code locations.

## DEBTR (Technical Debt Record) Authoring

Use template: `project_management/01_guidelines/documentation_standards/doc_templates/DEBTR_template.md`

**Required sections:**
- **Debt description**: What was implemented that deviates from the architecture vision.
- **Root cause**: Why was the deviation necessary?
- **Impact**: What quality attributes or future work are affected?
- **Remediation plan**: What TASK work item will address this?
- **Linked to**: ADR/IDR that was violated, the work item that introduced the debt.

## Architecture Review (ARCHREV) Authoring

Use template: `project_management/01_guidelines/documentation_standards/doc_templates/ARCHITECTURE_REVIEW_template.md`

**Trigger**: After each feature implementation (Step 6 of the implementation workflow).  
**Outcome**: Compliant / Deviated. Deviations → create DEBTR + TASK.

## Building Block View Conventions

- Show component hierarchy top-down.
- Each block: name, responsibility (one sentence), key interfaces.
- Highlight components that cross system boundaries.
- Reference source file or module path for each block.

## Traceability Rules

Every architecture document must link to at least one of:
- Project vision document or requirement (`REQ_XXXX`)
- Parent architecture concept (`ARC_XXXX`) or ADR (`ADR_XXXX`)
- Work item (`FEATURE_XXXX`, `BUG_XXXX`, or `TASK_XXXX`)
