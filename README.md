# doc.doc.md

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-0.1.0-orange.svg)](scripts/doc.doc.sh)

Lightweight Bash toolkit that orchestrates CLI tools to extract file metadata and generate Markdown documentation reports. Pure local processing, plugin-extensible, development foundation complete.

## Table of Contents

- [Overview](#overview)
- [Current Status](#current-status)
- [Installation](#installation)
- [Usage](#usage)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Overview

**doc.doc.md** automates file analysis by orchestrating existing Unix/Linux CLI tools (`file`, `stat`, etc.) to extract metadata and generate consistent Markdown reports using customizable templates.

**Core Principles:**
- **Composability**: Leverages proven Unix tools instead of reimplementing functionality
- **Extensibility**: Plugin architecture for custom analysis capabilities
- **Privacy**: 100% local processing - no cloud services or data transmission
- **Simplicity**: Pure Bash, minimal dependencies, runs anywhere Unix tools exist
- **Adaptability**: Mode-aware behavior automatically adjusts UX for interactive users and reliable automation for scripts/cron jobs

## Current Status

**v0.1.0 - Modular Architecture with Mode-Aware Capabilities** 🚧

Eight core features implemented:

- ✅ **Feature 0001**: Basic script structure (CLI parsing, help, version, error handling, platform detection)
- ✅ **Feature 0003**: Plugin listing functionality (`-p list` command)
- ✅ **Feature 0004**: Enhanced logging format with timestamps (ISO 8601, component identifiers)
- ✅ **Feature 0005**: Development containers (Ubuntu, Debian, Arch, Alpine)
- ✅ **Feature 0006**: Directory scanner component with recursive traversal
- ✅ **Feature 0007**: Workspace management system (JSON state storage, atomic writes, locking, integrity verification)
- ✅ **Feature 0015**: Modular component architecture (510-line monolith → 83-line entry + 16 components)
- ✅ **Feature 0016**: Interactive/Non-interactive mode detection (terminal detection, DOC_DOC_INTERACTIVE override)

**Architecture**: Architecture review ARCH_REVIEW_0015 approved with full compliance. Entry script reduced 84%, components organized across 4 domains (core, ui, plugin, orchestration). New mode-aware behavior concept (08_0010) and ADR_0008 define intelligent terminal detection for optimal interactive and automated execution.

**Testing**: 18 of 18 test suites passing (60 new workspace tests added).

**Requirements**: 50 accepted requirements (including new req_0057 interactive mode, req_0058 non-interactive mode behavior), 10 documented cross-cutting concepts, complete security threat modeling

**Features in Progress**: 21 total features across development lifecycle:
- **Done** (8): Core structure, plugin listing, logging, dev containers, directory scanner, workspace management, modular architecture, mode detection
- **Ready** (1): OCR PDF plugin (Feature 0002)
- **Backlog** (6): Interactive progress (0017), user prompts (0018), structured logging (0019), stat plugin (0020), workspace security (0013), advanced help (0014)
- **Analyze** (6): Template engine (0008), plugin execution (0009), report generator (0010), tool verification (0011), plugin security (0012)

## Installation

### Prerequisites

- Bash 4.0+ (check: `bash --version`)
- Standard Unix tools: `file`, `stat`, `grep`, `find`

### Quick Start

```bash
# Clone repository
git clone https://github.com/your-org/doc.doc.md.git
cd doc.doc.md

# Make script executable
chmod +x scripts/doc.doc.sh

# Verify installation
./scripts/doc.doc.sh --version
```

## Usage

### Current Commands

**Display help:**
```bash
./scripts/doc.doc.sh --help
```

**Show version:**
```bash
./scripts/doc.doc.sh --version
```

**List available plugins:**
```bash
./scripts/doc.doc.sh -p list
```

**Enable verbose logging:**
```bash
./scripts/doc.doc.sh --verbose -p list
```

### Logging Format

The script uses a structured logging format with timestamps and component identifiers:

**Format**: `[TIMESTAMP] [LEVEL] [COMPONENT] Message`

**Example output:**
```
[2026-02-10T14:30:45] [INFO] [MAIN] Script initialization complete
[2026-02-10T14:30:45] [INFO] [PARSER] Verbose mode enabled
[2026-02-10T14:30:46] [INFO] [PLATFORM] Detected platform: ubuntu
[2026-02-10T14:30:46] [ERROR] [PLUGIN] Plugin execution failed: missing descriptor
```

**Log Levels**:
- `DEBUG` - Detailed diagnostic information (verbose mode only)
- `INFO` - General informational messages (verbose mode only)
- `WARN` - Warning messages (always shown)
- `ERROR` - Error messages (always shown)

**Timestamps**: ISO 8601 format in UTC (e.g., `2026-02-10T14:30:45`)

**Components**: Identifies the source of each log entry (e.g., `MAIN`, `PARSER`, `PLUGIN`, `SCANNER`)

### Exit Codes

- `0` - Success
- `1` - Invalid arguments
- `2` - File/directory error
- `3` - Plugin execution failure
- `4` - Report generation failure
- `5` - Workspace error

### Mode-Aware Behavior

The toolkit automatically adapts its behavior based on execution context:

**Interactive Mode** (terminal attached):
- Live progress indicators and real-time feedback
- Colored output for improved readability
- User prompts for confirmation and control
- Rich error messages with suggestions

**Non-Interactive Mode** (automated/scripted):
- Structured, machine-parseable log output
- Non-blocking execution (no user prompts)
- Predictable exit codes for integration
- Suitable for cron jobs, CI/CD pipelines, background processes

**Mode Detection**: Automatic via terminal attachment test (`-t 0` and `-t 1`)

**Manual Override**: Set `DOC_DOC_INTERACTIVE=true` or `false` to force a specific mode

**Examples**:
```bash
# Interactive mode (default when run at terminal)
./scripts/doc.doc.sh -d ./docs -t ./reports

# Non-interactive mode (automatic in pipes/redirects)
./scripts/doc.doc.sh -d ./docs -t ./reports > output.log

# Force non-interactive mode (testing)
DOC_DOC_INTERACTIVE=false ./scripts/doc.doc.sh -d ./docs -t ./reports
```

See [08_0010_mode_aware_behavior.md](01_vision/03_architecture/08_concepts/08_0010_mode_aware_behavior.md) for architecture details.

### Planned Usage (Roadmap)

When directory analysis is implemented:

```bash
# Analyze directory with template
./scripts/doc.doc.sh -d /path/to/docs -m template.md -t ./output -w ./workspace

# Options (not yet implemented):
#   -d <directory>   Directory to analyze
#   -m <template>    Markdown template file
#   -t <target>      Output directory for reports
#   -w <workspace>   Workspace directory for state storage
#   -f               Enable fullscan mode
```

## Development Setup

### Using Development Containers (Recommended)

The project provides pre-configured dev containers for all supported platforms:

1. **Prerequisites**: [VS Code](https://code.visualstudio.com/) + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Available Containers:**
   - **Ubuntu 22.04** (`.devcontainer/ubuntu/`) - Primary development environment
   - **Debian 12** (`.devcontainer/debian/`) - Debian-based testing
   - **Arch Linux** (`.devcontainer/arch/`) - Rolling release testing
   - **Generic Alpine** (`.devcontainer/generic/`) - Minimal environment

3. **Launch:**
   - Open repository in VS Code
   - Run: `Dev Containers: Reopen in Container`
   - Select desired platform
   - Container builds and provisions automatically

4. **Included Tools:**
   - Bash 5.x with completion
   - Git, curl, jq (JSON parsing)
   - Testing frameworks
   - Common CLI tools for plugin development

**Benefits**: Consistent environments, instant setup, platform-specific testing, no host system conflicts.

### Manual Setup

```bash
# Clone repository
git clone https://github.com/your-org/doc.doc.md.git
cd doc.doc.md

# Verify Bash version
bash --version  # Requires 4.0+

# Run tests to verify environment
./tests/run_all_tests.sh
```

## Testing

### Test Structure

```
tests/
├── run_all_tests.sh              # Execute all test suites
├── helpers/test_helpers.sh       # Shared utilities and assertions
├── unit/                         # Component tests (8 suites)
│   ├── test_script_structure.sh
│   ├── test_help_system.sh
│   ├── test_argument_parsing.sh
│   └── ...
├── integration/                  # Multi-component tests
│   └── test_complete_workflow.sh
└── system/                       # End-to-end scenarios
    └── test_user_scenarios.sh
```

### Running Tests

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific suite
./tests/unit/test_help_system.sh
./tests/integration/test_complete_workflow.sh

# Run with verbose output
VERBOSE=true ./tests/run_all_tests.sh
```

**Current Status**: 18 of 18 test suites passing. See [tests/README.md](tests/README.md) for details.

## Project Structure

```
doc.doc.md/
├── scripts/
│   ├── doc.doc.sh              # Main entry script (83 lines)
│   ├── template.doc.doc.md     # Default report template
│   ├── components/             # Modular component architecture
│   │   ├── README.md           # Component documentation (343 lines)
│   │   ├── core/               # Core utilities (foundation layer)
│   │   │   ├── constants.sh    # Global constants and configuration
│   │   │   ├── logging.sh      # Logging infrastructure
│   │   │   ├── mode_detection.sh   # Interactive mode detection
│   │   │   ├── error_handling.sh  # Error handling and cleanup
│   │   │   └── platform_detection.sh  # Platform detection
│   │   ├── ui/                 # User interface (presentation layer)
│   │   │   ├── argument_parser.sh  # CLI argument parsing
│   │   │   ├── help_system.sh  # Help text and documentation
│   │   │   └── version_info.sh # Version information display
│   │   ├── plugin/             # Plugin management (domain layer)
│   │   │   ├── plugin_parser.sh    # JSON descriptor parsing
│   │   │   ├── plugin_discovery.sh # Plugin discovery and validation
│   │   │   ├── plugin_display.sh   # Plugin listing and formatting
│   │   │   └── plugin_executor.sh  # Plugin execution orchestration
│   │   └── orchestration/      # Workflow orchestration (domain layer)
│   │       ├── scanner.sh          # Directory and file scanning
│   │       ├── workspace.sh        # Workspace management
│   │       ├── template_engine.sh  # Template processing
│   │       └── report_generator.sh # Report generation
│   └── plugins/                # Plugin directory structure
│       ├── all/                # Cross-platform plugins
│       └── ubuntu/             # Ubuntu-specific plugins
│
├── tests/                      # Comprehensive test suite
│   ├── run_all_tests.sh        # Master test runner
│   ├── unit/                   # Component tests (11 suites)
│   ├── integration/            # Multi-component tests (1 suite)
│   └── system/                 # End-to-end tests (3 suites)
│
├── 01_vision/                  # Project vision and requirements
│   ├── 01_project_vision/      # Vision document
│   ├── 02_requirements/        # Requirements lifecycle (50 accepted)
│   ├── 03_architecture/        # Arc42 architecture documentation
│   └── 04_security/            # Security architecture and threat models
│
├── 02_agile_board/             # Kanban workflow (21 features total)
│   ├── 02_analyze/             # Analysis phase (6 features)
│   ├── 03_ready/               # Ready for implementation (1: 0002)
│   ├── 04_backlog/             # Prioritized backlog (6 features: 0009,0013-0014,0017-0020)
│   ├── 05_implementing/        # In progress (0 features)
│   ├── 06_done/                # Completed (8: 0001,0003-0007,0015-0016)
│   ├── 07_obsoleted/           # Obsoleted items
│   └── 08_rejected/            # Rejected items
│
├── 03_documentation/           # Implementation docs
│   ├── 01_architecture/        # Architecture Decision Records, compliance reviews
│   └── 02_tests/               # Test plans and reports
│
├── .devcontainer/              # Development containers
│   ├── ubuntu/                 # Ubuntu 22.04 environment
│   ├── debian/                 # Debian 12 environment
│   ├── arch/                   # Arch Linux environment
│   └── generic/                # Alpine-based minimal environment
│
└── .github/agents/             # Specialized automation agents
    ├── developer.agent.md
    ├── tester.agent.md
    ├── architect.agent.md
    ├── license-governance.agent.md
    ├── requirements-engineer.agent.md
    ├── readme-maintainer.agent.md
    └── security-review.agent.md
```

## Roadmap

### Phase 1: Foundation (Complete)
- ✅ Script structure with CLI parsing and help system  
- ✅ Plugin listing functionality
- ✅ Enhanced logging with timestamps and component identifiers
- ✅ Development containers for 4 platforms
- ✅ Test infrastructure (18 suites, 18 passing)
- ✅ 50 accepted requirements with complete lifecycle traceability
- ✅ Modular component architecture (Feature 0015) - 84% code reduction
- ✅ Architecture compliance framework (ARCH_REVIEW_0015 approved)
- ✅ Directory scanner component (Feature 0006)
- ✅ Mode-aware behavior architecture (Concept 08_0010, ADR_0008)
- ✅ Interactive/non-interactive mode detection (Feature 0016)

### Phase 2: Mode-Aware Execution (In Progress)
- ✅ Mode detection - automatic terminal detection (Feature 0016) - COMPLETE
- 🔜 Structured logging enhancement (Feature 0019, High Priority)
- 🔜 Interactive progress display with live feedback (Feature 0017)
- 🔜 User prompt system for interactive control (Feature 0018)
- ✅ Workspace management - JSON state storage (Feature 0007)
- 🔄 Tool availability verification (Feature 0011)

### Phase 3: Core Analysis (Ready to Start)
- 🔜 OCR PDF plugin (Feature 0002) - ready for implementation
- 🔜 Stat plugin - basic file metadata extraction (Feature 0020, High Priority)
- ✅ Directory traversal and file discovery (Feature 0006) - complete
- Template-based report generation (Feature 0010)
- Plugin execution engine (Feature 0009)

### Phase 4: Plugin Extensibility (Planned)
- Plugin descriptor validation and security (Feature 0012)
- Data-driven workflow orchestration
- Plugin management commands (info, enable, disable)
- Advanced help system with examples (Feature 0014)
- Example plugins (OCR, PDF analysis, stat)

### Phase 5: Advanced Features (Future)
- Aggregated summary reports
- Advanced template engine (conditionals, loops) (Feature 0008)
- Performance monitoring and metrics
- Security audit logging
- Workspace security enhancements (Feature 0013)

**See**: [Accepted Requirements](01_vision/02_requirements/03_accepted/) for detailed specifications

## Contributing

### Quick Start

1. Read [project vision](01_vision/01_project_vision/01_vision.md) and [architecture](01_vision/03_architecture/)
2. Check [agile board](02_agile_board/) for current work items
3. Review [agent system](AGENTS.md) for development workflow
4. Fork repository and set up dev container
5. Follow TDD: write tests first, then implementation
6. Ensure all quality gates pass (tests, architecture compliance, license verification)

### Development Workflow

This project uses **agent-driven development**:

- **Developer Agent**: Implements features from backlog
- **Tester Agent**: Creates tests (TDD) and validates implementations
- **Architect Agent**: Verifies architecture compliance
- **Security Review Agent**: Reviews for vulnerabilities
- **License Governance Agent**: Ensures GPL-3.0 compatibility

**Quality Gates** (all required):
- ✅ All tests passing (unit, integration, system)
- ✅ Architecture compliance verified
- ✅ Security review completed
- ✅ License compatibility confirmed
- ✅ Documentation updated

### Code Standards

- Strict Bash mode: `set -euo pipefail`
- POSIX-compliant where possible
- Function-based modular design
- Comprehensive error handling
- Multi-level logging with timestamps and component identifiers
  - Format: `[TIMESTAMP] [LEVEL] [COMPONENT] Message`
  - ISO 8601 timestamps in UTC
  - Log levels: DEBUG, INFO, WARN, ERROR
- Comments for complex logic

### Testing

- Follow TDD: tests before implementation
- Cover happy paths and error cases
- 100% of new code tested
- Run full test suite: `./tests/run_all_tests.sh`

### Documentation

- Update README for structural changes
- Create Architecture Decision Records (ADRs) for design choices
- Link implementations to requirements
- Maintain test documentation (plans and reports)

### Ways to Contribute

- **Report Bugs**: [GitHub Issues](https://github.com/PeculiarMind/doc.doc.md/issues) with reproduction steps
- **Suggest Features**: Propose via issues with use case justification
- **Submit Code**: Fork, implement with tests, create PR
- **Improve Docs**: Documentation updates always welcome
- **Write Tests**: Expand test coverage

**For New Contributors**: Look for `good-first-issue` labels or start with documentation improvements.

**See**: [copilot-instructions.md](.github/copilot-instructions.md) for complete agent system details

## License

**GNU General Public License v3.0 (GPL-3.0)**

This software is free and open source. You can use, modify, and distribute it under the terms of GPL-3.0.

**Key Terms**:
- ✅ Use for any purpose
- ✅ Study and modify source code
- ✅ Share and distribute
- 📋 Modifications must be shared under GPL-3.0
- 📋 Include original license and copyright notices
- 📋 Document significant changes
- 📋 Provide source code when distributing

**License Compliance**: Automated License Governance Agent verifies all dependencies and contributions for GPL-3.0 compatibility.

**Full License**: See [LICENSE](LICENSE)

---

**Project maintained by**: doc.doc.md Contributors  
**Questions?**: [Open an issue](https://github.com/PeculiarMind/doc.doc.md/issues)  
**Agent System**: See [AGENTS.md](AGENTS.md) for development automation details
