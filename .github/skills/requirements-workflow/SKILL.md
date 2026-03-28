---
name: requirements-workflow
description: "Use when: deriving, analyzing, refining, or managing requirements from project vision documents. Covers the full lifecycle from extraction to accepted/rejected states."
---

# Requirements Engineering Workflow

## Step 1 — Requirements Extraction
**Agent:** requirements  
**Action:** Scan `project_management/02_project_vision/01_project_goals/**/*.md` for explicit and implicit requirements. Create requirement files using the template at `project_management/01_guidelines/documentation_standards/doc_templates/REQUIREMENT_template.md`.  
**Output:** One or more `REQ_XXXX_*.md` files in `project_management/02_project_vision/02_requirements/01_funnel/`.  
**Next:** Requirements Assessment.

## Step 2 — Requirements Assessment
**Agent:** requirements  
**Mode:** Interview — ask clarifying questions to refine requirements. Identify conflicts, ambiguities, and dependencies. Document findings.  
**Input:** Requirement files from Step 1 in `01_funnel/`.  
**Output:** Refined requirement files moved to the appropriate state folder:
- `01_funnel/` — newly extracted, unreviewed
- `02_analyze/` — under active analysis
- `03_accepted/` — approved for implementation
- `04_obsoleted/` — no longer relevant
- `05_rejected/` — decided not to implement

## Lifecycle Rules
- **Accepted, Obsoleted, Rejected** are read-only states — metadata and comments only, no content changes.
- Traceability to vision sections must be maintained in every requirement file.
- IDs use the format `REQ_XXXX` (functional) or `REQ_SEC_XXXX` (security). Always verify the next available ID before creating a new file.
