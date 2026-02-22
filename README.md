# ProTemp.AI — Project Template

ProTemp is a ready-to-use **project template** that provides a standardised folder structure, document templates, and AI-agent personas for managing the full lifecycle of a software project — from vision and requirements through architecture, implementation, testing, and documentation.

Clone or fork this repository to bootstrap a new project with sensible defaults for project management, quality assurance, and architecture documentation.

## Key Features

- **Structured project management** — predefined folders for vision, planning boards, roadmaps, and reporting.
- **Arc42-based architecture docs** — both a vision layer (what should be) and an implementation layer (what is), following the proven 12-section arc42 template.
- **Document templates** — ready-made templates for requirements, architecture decisions, constraints, work items, test reports, security reviews, security analysis scopes, technical debt records, and more.
- **Documentation standards** — a central registry that defines document types, naming conventions, storage locations, and linked templates.
- **Kanban-style planning board** — work items flow through `funnel → analyze → ready → backlog → implementing → done` (plus obsoleted/rejected).
- **AI-agent personas** — seven specialised GitHub Copilot agent definitions (Architect, Developer, Tester, Requirements, Security, Documentation, License) with clear responsibilities, inputs, outputs, and limitations.
- **Workflow definitions** — documented workflows for requirements engineering and implementation that agents can follow autonomously.

## Repository Structure

```
ProTemp/
├── .github/
│   ├── copilot-instructions.md          # Copilot agent orchestration rules
│   └── agents/                          # Agent persona definitions
│       ├── architect.agent.md
│       ├── developer.agent.md
│       ├── documentation.agent.md
│       ├── license.agent.md
│       ├── requirements.agent.md
│       ├── security.agent.md
│       └── tester.agent.md
│
├── project_management/
│   ├── 01_guidelines/                   # Standards, templates, workflows
│   │   ├── documentation_standards/
│   │   │   ├── documentation-standards.md
│   │   │   └── doc_templates/           # All document templates
│   │   └── workflows/                   # Process workflow definitions
│   ├── 02_project_vision/               # Vision & requirements
│   │   ├── 01_project_goals/
│   │   ├── 02_requirements/             # Funnel → Analyze → Accepted / Obsoleted / Rejected
│   │   ├── 03_architecture_vision/      # Arc42 sections 1–12 (target state)
│   │   └── 04_security_concept/         # Security methodology, asset catalog, threat models
│   │       ├── 01_security_concept.md   # STRIDE/DREAD framework
│   │       ├── 02_asset_catalog.md      # CIA-rated asset inventory
│   │       └── SAS_XXXX_*.md            # Security analysis scopes (threat models)
│   ├── 03_plan/
│   │   ├── 01_roadmap/
│   │   └── 02_planning_board/           # Kanban columns (funnel → done)
│   └── 04_reporting/
│       ├── 01_architecture_reviews/
│       ├── 02_tests_reports/
│       └── 03_security_reviews/
│
├── project_documentation/
│   ├── 01_architecture/                 # Arc42 sections 1–12 (implemented state)
│   ├── 02_ops_guide/
│   ├── 03_user_guide/
│   └── 04_dev_guide/
│
├── AGENTS.md                            # Central registry of all available agents
├── CREDITS.md
├── LICENSE.md
└── README.md
```

## Getting Started

1. **Clone or fork** this repository.
2. Replace placeholder content in `project_management/02_project_vision/01_project_goals/` with your project's vision.
3. Start deriving requirements — the Requirements agent or the workflow in `project_management/01_guidelines/workflows/requirements_engineering_workflow.md` will guide you.
4. Use the document templates in `project_management/01_guidelines/documentation_standards/doc_templates/` whenever you create a new artifact.
5. Consult `project_management/01_guidelines/documentation_standards/documentation-standards.md` for naming conventions and storage locations.
6. Review [AGENTS.md](AGENTS.md) to understand available agents, workflows, and supporting standards.

## Tools

ProTemp includes utility scripts in `project_management/00_tools/` to automate common project maintenance tasks:

### File/Directory Rename and Reference Updater

Automatically rename or move files and directories while updating all references throughout the workspace. Essential for refactoring project structure without breaking links.

```bash
# Rename a file and update all references
python3 project_management/00_tools/rename_and_update_refs.py \
  old_file.md new_file.md --dry-run

# Move a directory and update all nested file references  
python3 project_management/00_tools/rename_and_update_refs.py \
  old_folder/ new_folder/
```

**Features:**
- Updates references in markdown links, code, configs, and documentation
- Handles both files and directories recursively
- Supports various reference formats (plain text, quoted, backticks, etc.)
- Dry-run mode to preview changes before applying
- Automatic workspace detection

### Broken Reference Finder

Scan the workspace for broken references - links and textual references pointing to files that don't exist.

```bash
# Find all broken references
python3 project_management/00_tools/find_broken_refs.py

# Show detailed output
python3 project_management/00_tools/find_broken_refs.py --verbose
```

**Features:**
- Detects broken markdown links, quoted paths, and backticked references
- Scans documentation, code, and configuration files
- Reports line numbers and reference types
- Useful for pre-commit checks and CI/CD pipelines
- Exit code 1 if broken references found (CI-friendly)

See [project_management/00_tools/TOOLS.md](project_management/00_tools/TOOLS.md) for complete documentation and examples.

## AI Agent System

ProTemp ships with seven GitHub Copilot agent personas defined in `.github/agents/`. An orchestration layer in `.github/copilot-instructions.md` routes tasks to the most appropriate agent automatically.

See [AGENTS.md](AGENTS.md) for the complete agent registry, including supporting standards and workflow definitions.

| Agent | Responsibility |
|-------|---------------|
| **Architect** | Architecture vision & implementation compliance |
| **Developer** | Backlog selection, implementation, and close-out |
| **Tester** | Test planning, execution, and reporting |
| **Requirements** | Requirements elicitation and specification |
| **Security** | Security reviews and security concept maintenance |
| **Documentation** | User, ops, and dev guide maintenance |
| **License** | License compliance and dependency auditing |

## License

This project is licensed under the [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license. See [LICENSE.md](LICENSE.md) for details.

## Credits

Architecture documentation structure based on the [arc42](https://arc42.org) template by Dr. Gernot Starke and Dr. Peter Hruschka. See [CREDITS.md](CREDITS.md).
