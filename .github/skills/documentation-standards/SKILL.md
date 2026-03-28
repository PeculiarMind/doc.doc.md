---
name: documentation-standards
description: "Use when: creating or updating any project document (requirement, ADR, IDR, work item, test plan, test report, security review, architecture review, agent definition). Defines document types, locations, naming conventions, and templates."
---

# Documentation Standards

- Maintain a Table of Contents for all created documents and update it after structure changes.
- Keep content concise and precise; remove redundancy.
- Use clear headings and lists; avoid filler and duplicated content.
- Ensure all references and links are accurate. Use tools in `project_management/00_tools/` to verify links.
- Follow specified templates for each document type.
- Apply the `communication-standards` skill for tone and style in all written artifacts.

## Document Types

### Constraint Record (CR)
- **Purpose**: Document constraints that impact design and implementation.
- **Location**: `project_management/02_project_vision/03_architecture_vision/02_constraints/CR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/CR_template.md`

### Requirement (REQ)
- **Purpose**: Functional and non-functional requirements derived from project vision.
- **Location**: `project_management/02_project_vision/02_requirements/{{state}}/REQ_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/REQUIREMENT_template.md`

### Architecture Decision Record (ADR)
- **Purpose**: Architecture decisions made during the design phase.
- **Location**: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/ADR_template.md`

### Architecture Concept (ARC)
- **Purpose**: Architectural patterns and approaches addressing specific design problems.
- **Location**: `project_management/02_project_vision/03_architecture_vision/08_concepts/ARC_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/ARC_concept_template.md`

### Implementation Decision Record (IDR)
- **Purpose**: Architecture decisions made during the implementation phase.
- **Location**: `project_documentation/01_architecture/09_architecture_decisions/IDR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/IDR_template.md`

### Technical Debt Record (DEBTR)
- **Purpose**: Implemented deviations from architecture vision that cannot be immediately remediated.
- **Location**: `project_documentation/01_architecture/11_risks_and_technical_debt/DEBTR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/DEBTR_template.md`

### FEATURE / BUG / TASK (Work Items)
- **Purpose**: Work items on the planning board.
- **Location**: `project_management/03_plan/02_planning_board/*/FEATURE_XXXX_*.md` (or BUG_, TASK_)
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/WORKITEM_template.md`
- **IDs**: `FEATURE_XXXX`, `BUG_XXXX`, `TASK_XXXX`

### Test Plan
- **Purpose**: Define test scope, strategy, scenarios, and entry/exit criteria for a work item.
- **Location**: `project_management/04_reporting/02_tests_reports/testplan_{{item}}.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/TEST_PLAN_template.md`

### Test Report
- **Purpose**: Results of test executions.
- **Location**: `project_management/04_reporting/02_tests_reports/testreport_{{YYYY-MM-DD}}.{{SEQUENCE}}_{{TITLE}}.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/TEST_REPORT_template.md`
- **Naming example**: `testreport_2026-02-13.001_template_engine_coverage.md`

### Architecture Review (ARCHREV)
- **Purpose**: Architectural compliance assessments of implemented features.
- **Location**: `project_management/04_reporting/01_architecture_reviews/ARCHREV_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/ARCHITECTURE_REVIEW_template.md`

### Security Review (SECREV)
- **Purpose**: Security assessments of implemented features.
- **Location**: `project_management/04_reporting/03_security_reviews/SECREV_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/SECURITY_REVIEW_template.md`

### Security Analysis Scope (SAS)
- **Purpose**: Threat modeling (STRIDE/DREAD) for specific system scopes.
- **Location**: `project_management/02_project_vision/04_security_concept/SAS_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/security_analysis_scope_template.md`

### Agent Definition
- **Purpose**: Define purpose, expertise, responsibilities, limitations, and I/O for an agent.
- **Location**: `.github/agents/{{agent_name}}.agent.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/agent_template.md`
