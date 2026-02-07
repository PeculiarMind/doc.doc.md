# doc.doc.md

A lightweight, scriptable toolkit that orchestrates existing CLI tools to extract metadata and content insights from files, producing consistent Markdown reports using customizable templates.

## Project Status

**Early Development - Foundation Complete** 🚧

- ✅ Agent-driven development workflow established ([AGENTS.md](AGENTS.md))
- ✅ Vision and architecture documented ([01_vision/](01_vision/))
- ✅ 18 requirements accepted and ready for implementation
- ✅ Basic script structure implemented (Feature 0001 - [Done](02_agile_board/06_done/))
- ✅ Comprehensive test suite established ([tests/](tests/))
- ✅ Test documentation standards implemented
- ✅ License compliance workflow integrated
- 🚧 Core functionality implementation in progress
- 🚧 Plugin system development planned

## Overview

### Purpose
doc.doc.md automates file analysis and documentation generation by:
- **Orchestrating** existing Linux/Unix CLI tools instead of reinventing functionality
- **Extracting** comprehensive metadata (ownership, timestamps, content insights)
- **Generating** consistent Markdown reports using customizable templates
- **Processing** everything locally with no external dependencies or data transmission

### Core Philosophy
- **Composability**: Leverage existing proven tools (`file`, `stat`, `grep`, etc.)
- **Extensibility**: Plugin architecture allows adding custom analysis capabilities
- **Privacy**: 100% local processing - no cloud services, no data transmission
- **Simplicity**: Bash-based, minimal dependencies, runs anywhere Unix tools exist
- **Standards**: Follows Unix conventions, POSIX compliance, semantic versioning

## Features

### Current Capabilities (v0.1.0)
- ✅ **Script Foundation**: Argument parsing, help system, error handling, platform detection
- ✅ **Exit Code System**: Standard codes for different failure modes
- ✅ **Verbose Logging**: Multi-level logging (INFO, WARN, ERROR, DEBUG)
- ✅ **Modular Architecture**: Function-based design ready for feature additions
- ✅ **Test Infrastructure**: Unit, integration, and system test suites

### Planned Features
- 📋 **Directory Analysis**: Recursive scanning with file discovery
- 📋 **Metadata Extraction**: File type, ownership, timestamps, permissions
- 📋 **Template System**: Variable substitution in Markdown templates
- 📋 **Plugin Architecture**: Data-driven extensibility with automatic workflow ordering
- 📋 **Workspace Management**: JSON-based state storage for incremental analysis
- 📋 **Tool Verification**: Check dependencies and prompt for installation
- 📋 **Report Generation**: Per-file Markdown reports with customizable templates

See [vision document](01_vision/01_project_vision/01_vision.md) for complete feature roadmap and [accepted requirements](01_vision/02_requirements/03_accepted/) for detailed specifications.

## Project Structure

```
doc.doc.md/
├── 01_vision/                          # Project vision and planning
│   ├── 01_project_vision/              # Core vision statement and goals
│   ├── 02_requirements/                # Requirements lifecycle management
│   │   ├── 01_funnel/                  # New requirements under consideration
│   │   ├── 02_analyze/                 # Requirements being analyzed
│   │   ├── 03_accepted/                # ✅ 18 approved requirements ready for implementation
│   │   ├── 04_obsolete/                # Archived requirements
│   │   └── 05_rejected/                # Rejected requirements with rationale
│   └── 03_architecture/                # Arc42 architecture vision
│       ├── 01_introduction_and_goals/  
│       ├── 02_architecture_constraints/
│       ├── 05_building_block_view/     # Component design
│       ├── 06_runtime_view/            # Execution flows
│       ├── 08_concepts/                # Plugin, workspace, CLI concepts
│       ├── 09_architecture_decisions/  # Design decisions
│       └── 10_quality_requirements/    # Quality goals and scenarios
│
├── 02_agile_board/                     # Kanban workflow tracking
│   ├── 01_funnel/                      # New work items
│   ├── 02_analyze/                     # Work under analysis
│   ├── 03_ready/                       # Ready for development
│   ├── 04_backlog/                     # Prioritized backlog
│   ├── 05_implementing/                # In active development
│   └── 06_done/                        # ✅ Completed features
│
├── 03_documentation/                   # Implementation documentation
│   ├── 01_architecture/                # Actual implemented architecture
│   │   ├── 05_building_block_view/     # Implemented components
│   │   ├── 06_runtime_view/            # Runtime behavior
│   │   ├── 09_architecture_decisions/  # Implementation decisions (ADRs)
│   │   └── 99_cross_references/        # Traceability between vision and implementation
│   └── 02_tests/                       # Test documentation
│       ├── testplan_*.md               # Test plans (created by Tester Agent)
│       └── testreport_*.md             # Test execution reports
│
├── .github/
│   ├── agents/                         # Specialized automation agents
│   │   ├── developer.agent.md          # Feature implementation workflow
│   │   ├── tester.agent.md             # TDD test creation and execution
│   │   ├── architect.agent.md          # Architecture compliance verification
│   │   ├── license-governance.agent.md # License compliance validation
│   │   ├── requirements-engineer.agent.md
│   │   └── readme-maintainer.agent.md  
│   └── copilot-instructions.md         # Agent system documentation
│
├── scripts/
│   ├── doc.doc.sh                      # Main analysis script
│   ├── template.doc.doc.md             # Default Markdown report template
│   └── plugins/                        # Plugin directory structure
│       ├── all/                        # Cross-platform plugins
│       └── ubuntu/                     # Platform-specific plugins
│
├── tests/                              # Comprehensive test suite
│   ├── run_all_tests.sh                # Master test runner
│   ├── helpers/                        # Shared test utilities
│   ├── unit/                           # Unit tests
│   ├── integration/                    # Integration tests
│   └── system/                         # End-to-end tests
│
├── AGENTS.md                           # Agent registry and usage guide
├── LICENSE                             # GNU General Public License v3.0
└── README.md                           # This file
```

## Getting Started

### Prerequisites
- **Bash**: Version 4.0 or higher
- **Common Unix utilities**: `file`, `stat`, `grep`, `find`, `uname`
- **Git**: For version control and repository management
- **Platform**: Linux or Unix-based system (tested on Ubuntu)

### Installation

```bash
# Clone the repository
git clone https://github.com/PeculiarMind/doc.doc.md.git
cd doc.doc.md

# Make the main script executable
chmod +x scripts/doc.doc.sh

# Verify installation (displays help)
./scripts/doc.doc.sh -h
```

### Quick Start

**Note**: Core analysis features are under development. Current implementation provides the foundational script structure.

```bash
# Display help and available options
./scripts/doc.doc.sh -h

# Show version information
./scripts/doc.doc.sh --version

# Enable verbose logging
./scripts/doc.doc.sh -v

# Planned usage pattern (implementation in progress)
./scripts/doc.doc.sh -d <source_directory> \
                     -m <template_file> \
                     -t <target_directory> \
                     -w <workspace_directory> \
                     [-v] [-f]
```

### Usage Examples

#### Basic Analysis (Planned)
```bash
# Analyze a directory with default template
./scripts/doc.doc.sh \
    -d ./my_documents \
    -m ./scripts/template.doc.doc.md \
    -t ./analysis_output \
    -w ./.doc.doc_workspace
```

#### Verbose Analysis with Full Scan (Planned)
```bash
# Enable verbose logging and force full rescan
./scripts/doc.doc.sh \
    -d ./project_files \
    -m ./custom_template.md \
    -t ./reports \
    -w ./.workspace \
    -v \
    -f
```

#### Plugin Management (Planned)
```bash
# List available plugins
./scripts/doc.doc.sh -p list

# Show plugin information
./scripts/doc.doc.sh -p info <plugin_name>
```

### Command-Line Options

| Option | Long Form | Description | Status |
|--------|-----------|-------------|--------|
| `-h` | `--help` | Display help information and exit | ✅ Implemented |
| `-v` | `--verbose` | Enable verbose logging output | ✅ Implemented |
| `--version` | | Display version information | ✅ Implemented |
| `-d <path>` | | Source directory to analyze | 📋 Planned |
| `-m <path>` | | Markdown template file path | 📋 Planned |
| `-t <path>` | | Target directory for output reports | 📋 Planned |
| `-w <path>` | | Workspace directory for metadata storage | 📋 Planned |
| `-f` | `--fullscan` | Force full rescan (ignore workspace cache) | 📋 Planned |
| `-p <cmd>` | `--plugin <cmd>` | Plugin management (list, info) | 📋 Planned |

### Workspace Directory

The workspace directory (`-w`) serves as a persistent data layer:

- **Purpose**: Stores scan metadata, document information, and state
- **Format**: JSON files for machine and human readability
- **Contents**:
  - Document metadata and extracted information
  - Last scan timestamps for incremental analysis
  - File summaries and content insights
  - State information for downstream tool integration
- **Benefits**:
  - Enables incremental analysis (only process changed files)
  - Provides consumable data for other tools in your pipeline
  - Maintains historical information across multiple scans

### Template System

Templates use variable substitution for consistent report generation:

**Available Variables** (defined in [template.doc.doc.md](scripts/template.doc.doc.md)):
- `${doc_name}` - Document name
- `${doc_categories}` - Document categories (comma-separated)
- `${doc_type}` - Document type classification
- `${filename}` - Base file name without path
- `${filepath_relative}` - Relative path from analysis root
- `${filepath_absolute}` - Full absolute path
- `${file_owner}` - File owner (user:group)
- `${file_created_at}` - Creation timestamp
- `${file_created_by}` - Creator (from metadata)
- `${file_last_analyzed_at}` - Last analysis timestamp
- `${doc_doc_version}` - Toolkit version used for analysis
- `${doc_content_summary}` - Generated content summary

**Customization**: Create your own template by copying and modifying the default template to match your documentation needs.

### Exit Codes

The script uses standard exit codes for integration with other tools:

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | `EXIT_SUCCESS` | Successful execution |
| 1 | `EXIT_INVALID_ARGS` | Invalid command-line arguments |
| 2 | `EXIT_FILE_ERROR` | File or directory access error |
| 3 | `EXIT_PLUGIN_ERROR` | Plugin execution failure |
| 4 | `EXIT_REPORT_ERROR` | Report generation failure |
| 5 | `EXIT_WORKSPACE_ERROR` | Workspace corruption or access error |

## Development Workflow

This project uses an **agent-driven development system** where specialized AI agents handle different aspects of the development lifecycle. This approach ensures consistent quality, comprehensive documentation, and systematic validation.

### Agent System Overview

The project employs six specialized agents that coordinate to implement features from vision through deployment:

| Agent | Purpose | Key Responsibilities |
|-------|---------|---------------------|
| **[Developer Agent](.github/agents/developer.agent.md)** | Feature implementation | Selects backlog items, creates branches, coordinates testing, implements features, manages PR creation |
| **[Tester Agent](.github/agents/tester.agent.md)** | Quality assurance | Creates test plans, implements TDD tests, executes test suites, generates test reports |
| **[Architect Agent](.github/agents/architect.agent.md)** | Architecture compliance | Reviews implementations, maintains architecture docs, verifies vision alignment |
| **[License Governance Agent](.github/agents/license-governance.agent.md)** | License compliance | Audits dependencies, verifies GPL-3.0 compatibility, ensures attribution |
| **[Requirements Engineer](.github/agents/requirements-engineer.agent.md)** | Requirements management | Extracts requirements from vision, manages lifecycle, maintains traceability |
| **[README Maintainer](.github/agents/readme-maintainer.agent.md)** | Documentation maintenance | Keeps README current, analyzes project changes, ensures documentation accuracy |

See [AGENTS.md](AGENTS.md) for complete agent documentation and usage guidelines.

### Development Lifecycle

#### 1. **Requirements Phase**
- Requirements Engineer extracts requirements from [project vision](01_vision/01_project_vision/01_vision.md)
- Requirements flow through lifecycle: `funnel` → `analyze` → `accepted`
- Accepted requirements documented in [01_vision/02_requirements/03_accepted/](01_vision/02_requirements/03_accepted/)
- **Status**: ✅ 18 requirements accepted and ready

#### 2. **Feature Implementation Phase**
The Developer Agent manages a comprehensive workflow:

```
1. Select item from backlog (02_agile_board/04_backlog/)
2. Create feature branch: feature/<ItemId>_<title_in_snake_case>
3. Hand off to Tester Agent
   ├─ Tester creates test plan (testplan_<item>.md)
   ├─ Tester implements tests (TDD - tests fail initially)
   └─ Tester hands back with tests ready
4. Implement feature to pass tests
5. Request architecture compliance verification
   ├─ Architect Agent reviews implementation
   ├─ Architect updates documentation (03_documentation/01_architecture/)
   └─ Architect confirms compliance or requests changes
6. Hand off to Tester for formal execution
   ├─ Tester executes complete test suite
   ├─ Tester creates test report (testreport_<item>_<date>.md)
   └─ Tester confirms tests pass or reports failures
7. Request license compliance verification
   ├─ License Governance Agent reviews changes
   ├─ Verifies GPL-3.0 compatibility
   └─ Confirms compliance or identifies issues
8. Move item to done (02_agile_board/06_done/)
9. Create pull request with all verification confirmations
```

#### 3. **Quality Gates**
All features must pass these gates before completion:
- ✅ All tests pass (unit, integration, system)
- ✅ Architecture compliance verified
- ✅ Architecture documentation updated
- ✅ License compliance verified
- ✅ Code follows conventions
- ✅ No merge conflicts

#### 4. **Documentation**
- **Test Plans**: Created in [03_documentation/02_tests/](03_documentation/02_tests/) by Tester Agent before implementation
- **Test Reports**: Generated after execution with detailed results and traceability
- **Architecture Docs**: Maintained in [03_documentation/01_architecture/](03_documentation/01_architecture/) by Architect Agent
- **ADRs**: Architecture Decision Records document implementation choices
- **Cross-References**: Maintain traceability between vision, requirements, and implementation

### Work Item Management

#### Agile Board Structure ([02_agile_board/](02_agile_board/))
1. **01_funnel/**: New ideas and feature requests
2. **02_analyze/**: Items under analysis and refinement
3. **03_ready/**: Ready for prioritization
4. **04_backlog/**: Prioritized and ready for implementation
5. **05_implementing/**: Currently in active development
6. **06_done/**: Completed and verified features

#### Current Board Status
- ✅ **Done**: Feature 0001 (Basic Script Structure)
- 📋 **In Funnel**: Feature 0002 (OCRmyPDF Plugin), Feature 0003 (Plugin Listing)

### Testing Strategy

Comprehensive testing follows TDD principles:

**Test Structure** ([tests/](tests/)):
- **Unit Tests** (`tests/unit/`): Individual function validation
- **Integration Tests** (`tests/integration/`): Component interaction testing
- **System Tests** (`tests/system/`): End-to-end user scenarios

**Test Process**:
1. Tester Agent creates tests **before** implementation
2. Tests initially fail (red phase)
3. Developer implements to make tests pass (green phase)
4. Refactor and optimize (refactor phase)
5. Formal test execution with report generation

**Test Documentation**:
- Test plans document strategy and test cases
- Test reports track execution history and results
- All tests linked to original requirements for traceability

Run tests:
```bash
# Run complete test suite
./tests/run_all_tests.sh

# Run specific test category
./tests/unit/test_script_structure.sh
./tests/integration/test_complete_workflow.sh
./tests/system/test_user_scenarios.sh
```

### Architecture

The project follows the **[arc42](https://arc42.org/)** architecture documentation framework:

**Architecture Vision** ([01_vision/03_architecture/](01_vision/03_architecture/)):
- Planned architecture and design intent
- Quality requirements and constraints
- Plugin concept and data-driven execution
- Solution strategies

**Implementation Documentation** ([03_documentation/01_architecture/](03_documentation/01_architecture/)):
- Actual implemented components
- Runtime behavior and interactions
- Architecture Decision Records (ADRs)
- Cross-references to requirements

**Key Architectural Principles**:
- **Plugin-based extensibility**: Data-driven execution flow
- **Workspace pattern**: Persistent state management
- **Tool orchestration**: Leverage existing CLI tools
- **Local-only processing**: Privacy and security by design
- **Modular bash functions**: Clean separation of concerns

### Code Quality Standards

**Bash Best Practices**:
- ✅ Strict mode enabled (`set -euo pipefail`)
- ✅ Function-based modular architecture
- ✅ Consistent naming conventions
- ✅ Comprehensive error handling
- ✅ Logging with multiple levels
- ✅ POSIX compliance where possible
- ✅ Entry point guard pattern

**Documentation Requirements**:
- Clear comments for complex logic
- Function headers with purpose and parameters
- Usage examples in help text
- Architecture decisions documented in ADRs

**Quality Verification**:
- All code tested before merge
- Architecture compliance verified
- License compatibility checked
- Documentation updated with implementation

## Contributing

We welcome contributions from the community! This project uses an agent-driven workflow to ensure quality and consistency.

### How to Contribute

#### 1. **Familiarize Yourself with the Project**
- Read the [project vision](01_vision/01_project_vision/01_vision.md)
- Review [accepted requirements](01_vision/02_requirements/03_accepted/)
- Study the [architecture vision](01_vision/03_architecture/)
- Check the [agile board](02_agile_board/) for current work

#### 2. **Understanding the Development Process**
- **Agent System**: Read [.github/copilot-instructions.md](.github/copilot-instructions.md) and [AGENTS.md](AGENTS.md)
- **Workflow**: Features follow Developer → Tester → Architect → License Governance flow
- **Quality Gates**: All contributions must pass testing, architecture compliance, and license verification
- **Documentation**: Updates to documentation are required with implementation changes

#### 3. **Ways to Contribute**

**Report Issues**:
- Use [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues)
- Provide clear description and reproduction steps
- Include system information (OS, bash version)
- Reference relevant requirements or documentation

**Suggest Features**:
- Check existing requirements in [01_vision/02_requirements/](01_vision/02_requirements/)
- Submit new ideas to the funnel via issues
- Explain use case and expected benefit
- Consider alignment with project vision

**Submit Code**:
- Fork the repository
- Follow the agent-driven workflow
- Ensure all quality gates pass
- Submit pull requests with comprehensive description
- Reference related requirements and test documentation

#### 4. **Development Guidelines**

**Code Standards**:
- Write POSIX-compliant bash where possible
- Use strict mode (`set -euo pipefail`)
- Follow existing function naming conventions
- Include comprehensive error handling
- Add appropriate logging statements
- Document complex logic with comments

**Testing Requirements**:
- Write tests before implementation (TDD)
- Ensure all existing tests continue to pass
- Cover happy paths and edge cases
- Test error handling thoroughly
- Document test strategy in test plan

**Documentation Standards**:
- Update README.md for structural changes
- Keep architecture documentation synchronized
- Document architecture decisions in ADRs
- Link implementations to requirements
- Maintain test documentation

**Commit Guidelines**:
- Write clear, descriptive commit messages
- Reference issue/requirement numbers
- Keep commits focused and atomic
- Include context in commit body

#### 5. **Pull Request Process**

Your PR should include:
- ✅ Clear title and description
- ✅ Reference to original requirement or issue
- ✅ Summary of changes and rationale
- ✅ Test plan and test results
- ✅ Architecture compliance confirmation
- ✅ License compliance verification
- ✅ Updated documentation

**Review Process**:
- Human reviewers will assess the submission
- Agents provide automated verification and documentation
- Address feedback and update as needed
- Approval requires passing all quality gates

#### 6. **License Compliance**

All contributions must be compatible with **GPL-3.0**:
- Submit only code you have rights to contribute
- Ensure dependencies are GPL-compatible
- Include proper attribution for third-party code
- Add copyright headers to new files
- License Governance Agent will verify compliance

#### 7. **Communication**

- **Questions**: Open GitHub Issues with "Question:" prefix
- **Discussions**: Use GitHub Discussions for broader topics
- **Bugs**: Report via Issues with clear reproduction steps
- **Features**: Propose via Issues with use case explanation

### For New Contributors

**Good First Issues**:
- Look for issues labeled `good-first-issue`
- Start with documentation improvements
- Help expand test coverage
- Improve error messages and logging

**Getting Help**:
- Review existing agent reports in the repository
- Study completed features in [02_agile_board/06_done/](02_agile_board/06_done/)
- Ask questions via GitHub Issues
- Reference the agent documentation for workflow guidance

### Recognition

Contributors are acknowledged in:
- Git commit history
- Release notes
- Project documentation
- Special recognition for significant contributions

Thank you for helping make doc.doc.md better!

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).

### What This Means

You are free to:
- ✅ Use this software for any purpose
- ✅ Study and modify the source code
- ✅ Share copies of the software
- ✅ Share your modifications

**With the requirement that**:
- 📋 You must share your modifications under GPL-3.0
- 📋 You must include the original license and copyright notices
- 📋 You must state significant changes you made
- 📋 You must make source code available when distributing

See [LICENSE](LICENSE) for the complete license text.

### License Compliance

This project uses automated **License Governance** to ensure GPL-3.0 compliance:
- All dependencies are verified for compatibility
- Third-party attributions are maintained
- License compliance is a required quality gate
- Compliance reports available: [LICENSE_COMPLIANCE_REPORT.md](LICENSE_COMPLIANCE_REPORT.md)

For questions about licensing, please open a GitHub Issue.

## Roadmap

### Phase 1: Foundation (Current) - Q1 2026
- [x] ✅ Project vision and architecture documented
- [x] ✅ Agent system established and operational
- [x] ✅ Requirements extracted and accepted (18 requirements)
- [x] ✅ Basic script structure implemented (Feature 0001)
- [x] ✅ Test infrastructure established
- [x] ✅ License compliance workflow integrated
- [ ] 🚧 Core directory scanning functionality
- [ ] 🚧 Basic metadata extraction

### Phase 2: Core Features - Q2 2026
- [ ] 📋 Recursive directory traversal
- [ ] 📋 Template-based report generation
- [ ] 📋 Workspace management system
- [ ] 📋 Tool availability verification
- [ ] 📋 Per-file Markdown reports

### Phase 3: Extensibility - Q3 2026
- [ ] 📋 Plugin architecture implementation
- [ ] 📋 Data-driven execution flow
- [ ] 📋 Plugin descriptor system
- [ ] 📋 Plugin discovery and listing
- [ ] 📋 Example plugins (OCRmyPDF, etc.)

### Phase 4: Enhancement - Q4 2026
- [ ] 📋 Advanced content extraction
- [ ] 📋 Integration patterns documentation
- [ ] 📋 Performance optimization
- [ ] 📋 Comprehensive documentation
- [ ] 📋 Example workflows and tutorials

### Future Considerations
- Community plugin repository
- Additional platform support
- Integration with common development tools
- Web interface for report viewing
- CI/CD integration examples

See [accepted requirements](01_vision/02_requirements/03_accepted/) for detailed feature specifications.

## Documentation

### Project Documentation Structure

| Documentation | Location | Purpose |
|--------------|----------|---------|
| **Vision** | [01_vision/01_project_vision/](01_vision/01_project_vision/) | Project goals and purpose |
| **Requirements** | [01_vision/02_requirements/03_accepted/](01_vision/02_requirements/03_accepted/) | Detailed feature specifications |
| **Architecture (Vision)** | [01_vision/03_architecture/](01_vision/03_architecture/) | Planned architecture and design |
| **Architecture (Implementation)** | [03_documentation/01_architecture/](03_documentation/01_architecture/) | Actual implemented architecture |
| **Test Plans** | [03_documentation/02_tests/](03_documentation/02_tests/) | Test strategy and test cases |
| **Test Reports** | [03_documentation/02_tests/](03_documentation/02_tests/) | Test execution results |
| **Agent System** | [.github/agents/](. github/agents/) & [AGENTS.md](AGENTS.md) | Development workflow agents |
| **API Documentation** | [scripts/doc.doc.sh](scripts/doc.doc.sh) | Inline code documentation |

### Quick Reference

**Need to understand...**
- **What the project does?** → Read [01_vision.md](01_vision/01_project_vision/01_vision.md)
- **How to use it?** → See [Getting Started](#getting-started) section above
- **How to contribute?** → Read [Contributing](#contributing) section
- **What's implemented?** → Check [02_agile_board/06_done/](02_agile_board/06_done/)
- **What's planned?** → Browse [01_vision/02_requirements/03_accepted/](01_vision/02_requirements/03_accepted/)
- **Architecture details?** → Study [03_documentation/01_architecture/](03_documentation/01_architecture/)
- **How agents work?** → Read [AGENTS.md](AGENTS.md)
- **Testing approach?** → See [tests/README.md](tests/README.md)

## Credits and Acknowledgments

This project builds upon and is inspired by excellent work from the open-source community.

### Architecture Framework
- **[arc42](https://arc42.org/)**: Architecture documentation template
- **License**: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- **Description**: Practical, pragmatic, and proven framework for communicating software systems and architectures

### Linux and Unix Tools
- **[Linux](https://www.kernel.org/)**: Created by Linus Torvalds and maintained by thousands of contributors worldwide
- **GNU Core Utilities**: Essential command-line tools (`file`, `stat`, `grep`, `find`, etc.)
- **Bash**: The Bourne Again Shell, scripting foundation of Unix/Linux systems
- **Open Source Community**: Thank you to the entire community for creating and maintaining the tools this project orchestrates

### Development Methodology
- **Test-Driven Development (TDD)**: Methodology promoting quality through tests-first approach
- **Agile/Kanban**: Work management principles for iterative development
- **Semantic Versioning**: Version numbering convention for clear release management

### Special Thanks
- Contributors who report issues and suggest improvements
- Users who provide feedback and use cases
- The broader open-source community for tools, libraries, and inspiration

## Support and Contact

### Getting Help

**Documentation**:
- Read this README thoroughly
- Check [01_vision/](01_vision/) for detailed specifications
- Review [tests/](tests/) for usage examples
- Study completed features in [02_agile_board/06_done/](02_agile_board/06_done/)

**Issues and Questions**:
- **Bug Reports**: [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues) with "Bug:" prefix
- **Feature Requests**: [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues) with "Feature:" prefix
- **Questions**: [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues) with "Question:" prefix
- **Discussions**: Use GitHub Discussions for broader conversations

**When Reporting Issues**:
- Include system information (OS, bash version)
- Provide reproduction steps
- Share relevant error messages or logs
- Reference documentation you've consulted
- Include minimal example to reproduce problem

### Project Information

- **Repository**: [https://github.com/PeculiarMind/doc.doc.md](https://github.com/PeculiarMind/doc.doc.md)
- **License**: GNU General Public License v3.0
- **Version**: 0.1.0 (Early Development)
- **Status**: Active Development
- **Language**: Bash/Shell Script
- **Platform**: Linux/Unix

---

**Last Updated**: February 7, 2026  
**README Maintained By**: README Maintainer Agent ([.github/agents/readme-maintainer.agent.md](.github/agents/readme-maintainer.agent.md))

For the latest updates, see the [commit history](https://github.com/PeculiarMind/doc.doc.md/commits) or check the [agile board](02_agile_board/) for current work items.
