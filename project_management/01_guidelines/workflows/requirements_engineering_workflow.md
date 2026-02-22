### Requirements Engineering Workflow

#### Step 1: Requirements Engineering
**Agent:** requirements.agent  
**Task:** Derive requirements from project vision documents. New requirements should be documented using the template located in `project_management/01_guidelines/documentation_standards/doc_templates/REQUIREMENT_template.md`. 
**Input:** Project vision documents located in `project_management/02_project_vision/01_project_goals/**/*.md`  
**Result:** one or more requirement specification documents stored in `project_management/02_project_vision/02_requirements/01_funnel/REQ_XXXX_*.md`
**Next Step:** Requirements Assessment

#### Step 2: Requirements Assessment
**Agent:** requirements.agent  
**Task:** The assessment should be done in interview mode with the user, where the agent asks questions to clarify and refine the requirements. The agent should also identify any potential conflicts or dependencies between requirements and document them accordingly. The final output should be a comprehensive requirements specification document that is clear, concise, and actionable for the development team.
**Input:** Requirements specification documents from Step 1 located in `project_management/02_project_vision/02_requirements/01_funnel/REQ_XXXX_*.md`  
**Result:** one or more refined requirement specification documents stored below `project_management/02_project_vision/02_requirements/` in corresponding subdirectories based on their status (e.g., `01_funnel/`, `02_analyze/`, etc.)