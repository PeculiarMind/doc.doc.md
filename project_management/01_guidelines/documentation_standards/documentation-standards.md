# Documentation Standards

- Maintain a Table of Contents for all created documents and update it after structure changes.
- Keep content concise and precise; remove redundancy.
- Use clear headings and lists; avoid filler and duplicated content.
- Ensure all references and links to other documents are accurate and up-to-date. Utilize the tools available in `project_management/00_tools/` to automate link verification and verify if tangled references are just used for examples or if they have to be corrected.
- Follow the specified templates for each document type to maintain consistency.
- Follow `project_management/01_guidelines/agent_behavior/communication_standards.md` for tone and style in all written artifacts.

## Documents

### Constraint Record (CR)
- **Purpose**: Document constraints that impact design and implementation.
- **Location**: `project_management/02_project_vision/03_architecture_vision/02_constraints/CR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/CR_template.md`
- **Linked to:** Project vision

### Requirement (REQ)
- **Purpose**: Document functional and non-functional requirements derived from the project vision.
- **Location**: `project_management/02_project_vision/02_requirements/{{state}}/REQ_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/REQUIREMENT_template.md`
- **Linked to:** Project vision, related requirements

### Architecture Decision Record (ADR)
- **Purpose**: Document architecture decisions made during the design phase.
- **Location**: `project_management/02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/ADR_template.md`
- **Linked to:** Relevant CRs, Solution Strategies, and other ADRs

### Implementation Decision Record (IDR)
- **Purpose**: Document architecture decisions made during the implementation phase.
- **Location**: `project_documentation/01_architecture/09_architecture_decisions/IDR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/IDR_template.md`
- **Linked to:** Relevant CRs, Solution Strategies, ADRs, and work items

### Technical Debt Record (DEBTR)
- **Purpose**: Document implemented deviations from the architecture vision that cannot be immediately remediated.
- **Location**: `project_documentation/01_architecture/11_risks_and_technical_debt/DEBTR_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/DEBTR_template.md`
- **Linked to:** Relevant CRs, ADRs, IDRs, and work items

### FEATURE
- **Purpose**: Represents a work item that implements a feature aligned with the project vision and requirements.
- **Location**: `project_management/03_plan/02_planning_board/*/FEATURE_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/WORKITEM_template.md`
- **Linked to:** Project vision documents, requirements, and work items it depends on or is related to

### BUG
- **Purpose**: Represents a work item that addresses a bug in the implementation.
- **Location**: `project_management/03_plan/02_planning_board/*/BUG_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/WORKITEM_template.md`
- **Linked to:** Project vision documents, requirements, and work items it depends on or is related to

### TASK
- **Purpose**: Represents a work item that describes a specific task to be completed, which doesn't directly implement a feature or fix a bug but is necessary for project progress.
- **Location**: `project_management/03_plan/02_planning_board/*/TASK_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/WORKITEM_template.md`
- **Linked to:** Project vision documents, requirements, and work items it depends on or is related to

### Test Report
- **Purpose**: Document the results of test executions, including passed and failed tests, issues found, and recommendations.
- **Location**: `project_management/04_reporting/02_tests_reports/testreport_{{YYYY-MM-DD}}.{{SEQUENCE}}_{{TITLE}}.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/TEST_REPORT_template.md`
- **Naming**: `testreport_{{YYYY-MM-DD}}.{{SEQUENCE}}_{{TITLE}}` (e.g., `testreport_2026-02-13.001_template_engine_coverage.md`)
- **Linked to:** Relevant work items, requirements, and test cases

### Test Plan
- **Purpose**: Define test scope, strategy, scenarios, and entry/exit criteria for a work item.
- **Location**: `project_management/04_reporting/02_tests_reports/testplan_{{item}}.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/TEST_PLAN_template.md`
- **Linked to:** Related work item, requirements, and test reports

### Architecture Review (ARCHREV)
- **Purpose**: Document architectural compliance assessments of implemented features.
- **Location**: `project_management/04_reporting/01_architecture_reviews/ARCHREV_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/ARCHITECTURE_REVIEW_template.md`
- **Linked to:** Work items, architecture vision, and DEBTR records

### Security Review (SECREV)
- **Purpose**: Document security assessments of implemented features.
- **Location**: `project_management/04_reporting/03_security_reviews/SECREV_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/SECURITY_REVIEW_template.md`
- **Linked to:** Work items, security concept, and related BUG records

### Security Analysis Scope (SAS)
- **Purpose**: Document comprehensive threat modeling analysis using STRIDE/DREAD methodologies for specific system scopes.
- **Location**: `project_management/02_project_vision/04_security_concept/SAS_XXXX_*.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/security_analysis_scope_template.md`
- **Linked to:** Security concept, work items, security requirements, security reviews, and test plans

### Agent Definition
- **Purpose**: Define the purpose, expertise, responsibilities, limitations, input requirements, and output format for an agent.
- **Location**: `.github/agents/{{agent_name}}.agent.md`
- **Template**: `project_management/01_guidelines/documentation_standards/doc_templates/agent_template.md`
- **Linked to:** Documentation standards, agent registry, and related workflows