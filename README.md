# doc.doc.md

## Purpose
This project provides a lightweight, scriptable toolkit that orchestrates CLI tools to extract metadata and content insights from files, producing consistent Markdown summaries using customizable templates.

## Project Status
**Early Development Stage**

- ✅ Vision and architecture documented ([01_vision/](01_vision/))
- ✅ Agent system established for workflow automation
- ✅ Template structure defined ([scripts/template.doc.doc.md](scripts/template.doc.doc.md))
- ✅ Core bash script skeleton created ([scripts/doc.doc.sh](scripts/doc.doc.sh))
- ✅ 20 requirements extracted from vision and documented in [funnel](01_vision/02_requirements/01_funnel/)
- 🚧 Requirements analysis and acceptance in progress
- 🚧 Tool integration and implementation in progress

## Project Structure

```
doc.doc.md/
├── 01_vision/              # Project vision, requirements, and architecture
│   ├── 01_project_vision/  # Core vision documents
│   ├── 02_requirements/    # Requirements lifecycle (funnel → analyze → accepted → active)
│   └── 03_architecture/    # Arc42 architecture documentation
├── 02_agile_board/         # Kanban-style work tracking
├── .github/
│   ├── agents/             # Specialized automation agents
│   └── copilot-instructions.md
├── scripts/
│   ├── doc.doc.sh          # Main analysis script (in development)
│   └── template.doc.doc.md # Markdown report template
├── AGENTS.md               # Agent registry
├── LICENSE                 # GPL-3.0 license
└── README.md
```

## Key Features (Planned)

- **Automated File Analysis**: Recursively scan directories and analyze file collections
- **Template-Based Reporting**: Generate consistent Markdown reports using customizable templates
- **CLI Tool Integration**: Leverage existing Linux tools (`file`, `stat`, `grep`) instead of reinventing functionality
- **Metadata Extraction**: Capture file ownership, timestamps, paths, and content summaries
- **Lightweight Design**: Minimal dependencies, runs locally without heavy runtimes
- **Privacy & Security**: All text analysis and processing performed offline with local tools only; no data transmitted to external services

## Setup / Usage

### Prerequisites
- Bash 4.0+
- Common UNIX utilities: `file`, `stat`, `grep`, `find`
- Git (for version control)

### Installation
```bash
# Clone the repository
git clone https://github.com/PeculiarMind/doc.doc.md.git
cd doc.doc.md

# Make scripts executable (when ready)
chmod +x scripts/doc.doc.sh
```

### Intended Usage
**Note**: Core implementation is in progress. The planned usage pattern:

```bash
# Analyze a directory and generate reports
./scripts/doc.doc.sh -d <directory_to_analyze> -m <markdown_template> -t <target_directory> -w <workspace_directory> [-v]

# Options:
#   -d : Source directory to analyze (required)
#   -m : Markdown template file (required)
#   -t : Target directory for output reports (required)
#   -w : Workspace directory for metadata storage (required)
#        Stores scan state, metadata, and timestamps in JSON format
#        Enables incremental analysis and downstream tool integration
#   -v : Verbose output
#   -h : Show help

# Example:
./scripts/doc.doc.sh -d ./src -m ./scripts/template.doc.doc.md -t ./analysis_output -w ./.doc.doc_workspace -v
```

### Workspace Directory
The workspace (`-w`) directory is a persistent data layer that stores:
- Document metadata and extracted information in JSON format
- Last scan timestamps for detecting changes
- Document summaries and file information
- State information consumable by other tools in your pipeline

### Template Variables
The [template.doc.doc.md](scripts/template.doc.doc.md) supports these placeholders:
- `${doc_name}` - Document name
- `${doc_categories}` - Document categories
- `${doc_type}` - Document type
- `${filename}` - Base file name
- `${filepath_relative}` - Relative path
- `${filepath_absolute}` - Absolute path
- `${file_owner}` - File owner
- `${file_created_at}` - Creation timestamp
- `${file_created_by}` - Creator
- `${file_last_analyzed_at}` - Last analysis timestamp
- `${doc_doc_version}` - Tool version
- `${doc_content_summary}` - Content summary

## Development

### Agent System
This project uses specialized agents for complex tasks. Available agents:

- **[README Maintainer Agent](.github/agents/readme-maintainer.agent.md)**: Documentation maintenance
- **[License Governance Agent](.github/agents/license-governance.agent.md)**: License compliance verification
- **[Requirements Engineer Agent](.github/agents/requirements-engineer.agent.md)**: Requirements lifecycle management

See [AGENTS.md](AGENTS.md) for complete documentation.

### Requirements Process
The project uses two parallel lifecycle processes:

**Requirements Lifecycle** (`01_vision/02_requirements/`):
1. **01_funnel**: Initial collection (✅ 20 requirements currently in funnel)
2. **02_analyze**: Detailed review and refinement
3. **03_accepted**: Approved by stakeholders, ready for implementation
4. **04_active**: Currently being implemented
5. **05_obsolete**: No longer relevant; archived
6. **06_rejected**: Explicitly rejected; rationale documented

**Agile Work Tracking** (`02_agile_board/`):
1. **01_funnel**: New work items
2. **02_analyze**: Work item analysis
3. **03_ready**: Ready for development
4. **04_backlog**: Prioritized backlog
5. **05_implementing**: In active development
6. **06_review**: Code review
7. **07_reviewing**: Under review process
8. **08_done**: Completed work

The Requirements Engineer Agent has extracted 20 formal requirements from the [vision document](01_vision/01_project_vision/01_vision.md), covering:
- 10 functional requirements (directory scanning, metadata extraction, reporting)
- 2 usability requirements (tool verification, installation prompts)
- 4 non-functional requirements (lightweight, composability, offline operation)
- 5 constraint requirements (local-only processing, no GUI, minimal dependencies)

These requirements are ready for analysis and stakeholder review.

## Contributing

Contributions are welcome! To contribute:

1. **Review the vision**: See [01_vision/01_project_vision/01_vision.md](01_vision/01_project_vision/01_vision.md)
2. **Use the agent system**: Follow guidance in [.github/copilot-instructions.md](.github/copilot-instructions.md)
3. **Update documentation**: 
   - Keep [AGENTS.md](AGENTS.md) synchronized when adding/modifying agents
   - Update this README for structural changes
4. **Keep it factual**: Only document implemented features
5. **Submit clear PRs**: Describe changes and rationale

### Coding Guidelines
- Write POSIX-compliant bash where possible
- Include usage help (`-h`) in all scripts
- Verify tool dependencies before execution
- Use the template system for consistent output
- Follow the script skeleton structure in [scripts/doc.doc.sh](scripts/doc.doc.sh)

## License
This project is licensed under the **GNU General Public License v3.0** (GPL-3.0). See [LICENSE](LICENSE) for full text.

## Roadmap

- [ ] Complete `doc.doc.sh` core implementation
- [ ] Implement tool dependency verification
- [ ] Add file metadata extraction functions
- [ ] Implement template variable substitution
- [ ] Create example analysis workflows
- [ ] Add unit tests for bash functions
- [ ] Document integration patterns for common tools

## Contact
For questions or issues, please use [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues).
