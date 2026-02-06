---
title: Architecture Decisions
arc42-chapter: 9
---

# 9. Architecture Decisions

This section documents significant architectural decisions, their rationale, alternatives considered, and implications.

## 9.1 ADR-001: Bash as Primary Implementation Language

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Need to choose implementation language for CLI tool orchestration system

### Decision

Implement the core orchestration logic in Bash shell scripting (v4.0+).

### Rationale

**Strengths**:
- **Ubiquitous Availability**: Present on all target platforms (Linux, macOS, WSL)
- **Native Process Control**: Direct access to process spawning and management
- **Zero Installation Overhead**: No runtime or compilation required
- **CLI Tool Integration**: Natural fit for invoking command-line tools
- **File System Operations**: Direct, efficient file system access
- **Low Learning Curve**: Familiar to system administrators and DevOps users

**Weaknesses**:
- **Limited Data Structures**: No native support for complex data structures
- **Error Handling**: Less robust than modern languages
- **Portability Concerns**: Shell-specific features may limit portability
- **Maintainability**: Complex logic harder to maintain than structured languages

### Alternatives Considered

**Python**:
- ✅ Better data structures, error handling, maintainability
- ❌ Requires Python runtime installation
- ❌ Additional dependency management (pip, virtualenv)
- ❌ Slower startup time
- **Decision**: Overkill for orchestration task, adds runtime dependency

**Go**:
- ✅ Fast, single binary, excellent error handling
- ❌ Compilation required
- ❌ Higher development complexity
- ❌ Less accessible to non-programmers
- **Decision**: Unnecessary complexity for script orchestration

**Node.js**:
- ✅ Good async capabilities, JSON handling
- ❌ Requires Node.js runtime
- ❌ Heavyweight for simple orchestration
- **Decision**: Too heavy for lightweight toolkit

### Implications

**Positive**:
- Users can run without installing additional software
- Easy to inspect, modify, and debug
- Natural integration with existing shell workflows
- Can invoke any CLI tool without wrappers

**Negative**:
- Complex data operations need external tools (jq for JSON)
- Must be careful with shell-specific features (use POSIX where possible)
- Testing requires special frameworks (bats, shunit2)

**Mitigation**:
- Use JSON workspace to handle complex data structures
- Follow POSIX standards for maximum portability
- Delegate complex logic to specialized plugins
- Document shell version requirements clearly

### Trade-offs Accepted

- **Simplicity over Sophistication**: Accept bash limitations for zero-dependency deployment
- **Composability over Integration**: Leverage external tools rather than built-in capabilities
- **Accessibility over Performance**: Bash adequate for use case, prioritize ease of use

---

## 9.2 ADR-002: JSON Workspace for State Persistence

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Need mechanism to store analysis state and support incremental updates

### Decision

Use JSON files in a workspace directory to persist analysis results and metadata.

### Rationale

**Strengths**:
- **Human-Readable**: Easy to inspect and debug
- **Widely Supported**: Standard format with excellent tool support
- **No Database Required**: File-based, no server dependencies
- **Tool Integration**: Easy to consume by downstream tools (jq, scripts, etc.)
- **Version Control Friendly**: Text format can be tracked in git
- **Flexible Schema**: Easy to add new fields without breaking compatibility

**Weaknesses**:
- **Performance**: Slower than binary formats for large datasets
- **Concurrency**: Requires explicit locking mechanisms
- **Query Capabilities**: No SQL-like queries (need jq or scripting)

### Alternatives Considered

**SQLite Database**:
- ✅ Excellent query capabilities, good performance, ACID properties
- ❌ Requires SQLite library (additional dependency)
- ❌ Less human-readable (binary format)
- ❌ Adds complexity for simple key-value lookups
- **Decision**: Overkill for file-to-metadata mapping

**Binary Format (MessagePack, Protocol Buffers)**:
- ✅ Faster parsing, smaller file sizes
- ❌ Not human-readable
- ❌ Requires additional tools for inspection
- ❌ More complex schema management
- **Decision**: Human-readability more valuable than performance

**Plain Text (Key=Value)**:
- ✅ Simple, bash-native parsing
- ❌ No nested structures
- ❌ Limited data type support
- ❌ Poor extensibility
- **Decision**: Insufficient for structured metadata

**XML**:
- ✅ Structured, well-supported
- ❌ Verbose, harder to parse in bash
- ❌ Less modern tooling
- **Decision**: JSON more compact and better tooling

### Implications

**Positive**:
- Simple debugging (cat workspace/file.json | jq)
- Easy integration with other tools
- No runtime dependencies beyond jq (optional)
- Incremental analysis straightforward (check timestamps)

**Negative**:
- Must implement file locking for concurrent access
- JSON parsing in bash requires jq or workarounds
- Large workspaces (1M+ files) may have I/O overhead

**Mitigation**:
- Use atomic writes (write temp, then rename)
- Implement file locking with .lock files
- Use jq when available, fall back to bash JSON parsing
- One JSON file per analyzed file (scalable, distributed I/O)

### Workspace Structure

```
workspace/
├── abc123def456.json        # File hash as filename
├── abc123def456.json.lock   # Lock file during write
├── fed654cba321.json
└── metadata.json            # Optional: Workspace-level metadata
```

### Trade-offs Accepted

- **Simplicity over Performance**: JSON adequate for expected use cases (thousands of files)
- **Human-Readability over Compactness**: Prefer debuggability
- **File-per-Document over Single-Database**: Better scalability, simpler locking

---

## 9.3 ADR-003: Data-Driven Plugin Orchestration

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Need to determine how plugins execute and in what order

### Decision

Automatically determine plugin execution order by analyzing data dependencies declared in plugin descriptors (consumes/provides). Plugins execute when their required data becomes available.

### Rationale

**Strengths**:
- **Zero Configuration**: Users don't specify execution order
- **Automatic Adaptation**: Adding/removing plugins automatically adjusts workflow
- **Composability**: New plugins integrate without configuration changes
- **Correctness**: Dependency analysis ensures proper execution order
- **Flexibility**: Supports complex, multi-level dependency chains

**Weaknesses**:
- **Complexity**: Requires dependency graph analysis and topological sorting
- **Debugging**: Execution order not explicitly specified, harder to reason about
- **Circular Dependencies**: Must detect and handle gracefully

### Alternatives Considered

**Fixed Execution Order**:
- ✅ Simple, predictable, easy to debug
- ❌ Fragile (breaks when plugins added/removed)
- ❌ Requires manual configuration
- ❌ Not composable
- **Decision**: Violates extensibility goal

**User-Defined Workflow**:
- ✅ Full control, explicit dependencies
- ❌ High configuration burden
- ❌ Error-prone (user must understand all dependencies)
- ❌ Requires workflow modeling knowledge
- **Decision**: From vision: "users do not need to model or maintain an explicit workflow"

**Priority-Based Execution**:
- ✅ Simple numeric ordering
- ❌ Doesn't express dependencies
- ❌ Fragile when priorities conflict
- ❌ Requires manual priority assignment
- **Decision**: Insufficient for complex dependencies

**Event-Driven (Pub/Sub)**:
- ✅ Highly decoupled
- ❌ Too complex for bash implementation
- ❌ Harder to reason about execution flow
- **Decision**: Over-engineered for use case

### Implications

**Positive**:
- Users can add custom plugins without modifying core
- System adapts automatically as plugins evolve
- Clear plugin contract (consumes/provides)
- Supports parallel execution of independent plugins (future)

**Negative**:
- Must implement graph algorithms (topological sort, cycle detection)
- Execution order not immediately obvious to users
- Requires clear error messages when dependencies fail

**Mitigation**:
- Provide `-v` verbose mode showing execution order
- Clear error messages for circular dependencies
- Document plugin contract explicitly
- Log which plugins execute and why

### Implementation Requirements

**Dependency Graph Construction**:
```bash
# For each plugin:
for plugin in "${PLUGINS[@]}"; do
  consumes=$(jq -r '.consumes | keys[]' "${plugin}/descriptor.json")
  provides=$(jq -r '.provides | keys[]' "${plugin}/descriptor.json")
  # Build graph: if plugin B consumes what plugin A provides, edge A→B
done
```

**Topological Sort**:
```bash
# Kahn's algorithm or DFS-based topological sort
# Output: Ordered list of plugins
```

**Execution**:
```bash
for plugin in "${ORDERED_PLUGINS[@]}"; do
  if data_available_for_plugin "${plugin}"; then
    execute_plugin "${plugin}"
  else
    skip_plugin "${plugin}"
  fi
done
```

### Trade-offs Accepted

- **Complexity over Simplicity**: Accept graph algorithm complexity for user convenience
- **Implicit over Explicit**: Execution order emergent, not specified
- **Automation over Control**: System orchestrates, users trust the algorithm

---

## 9.4 ADR-004: Platform-Specific Plugin Directories

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Need to support tools that differ across operating systems

### Decision

Organize plugins in platform-specific directories (`plugins/ubuntu/`, `plugins/all/`). System detects platform at runtime and loads appropriate plugins.

### Rationale

**Strengths**:
- **Tool Availability**: Some tools only exist on certain platforms
- **Command Differences**: Tool flags differ (GNU stat vs BSD stat)
- **Graceful Degradation**: Missing plugins on unsupported platforms don't break core
- **Clear Organization**: Obvious which plugins work where

**Weaknesses**:
- **Duplication**: Some plugins may be duplicated across platforms
- **Maintenance**: Must maintain multiple versions of similar plugins
- **Testing**: Need to test on multiple platforms

### Alternatives Considered

**Single Plugin with Platform Detection**:
- ✅ No duplication, single source of truth
- ❌ Complex plugin logic to handle all platforms
- ❌ Harder to maintain and test
- **Decision**: Violates "simple plugins" principle

**Plugin Inheritance**:
- ✅ Share common logic, override platform-specific
- ❌ Too complex for bash implementation
- ❌ Harder to understand
- **Decision**: Over-engineered

**Runtime Platform Checks in Each Plugin**:
- ✅ Single plugin file
- ❌ Every plugin must handle all platforms
- ❌ Duplicated platform detection logic
- **Decision**: Inefficient, error-prone

### Implications

**Positive**:
- Clear plugin organizations
- Simple per-platform plugin implementation
- Easy to add platform support (create new directory)
- Plugins can use platform-native tool syntax

**Negative**:
- Duplicate plugins for cross-platform tools
- More directory traversal during discovery

**Mitigation**:
- Use `plugins/all/` for truly cross-platform plugins
- Document platform-specific plugin development guidelines
- Minimize platform-specific plugins where possible

### Directory Structure

```
plugins/
├── all/                  # Cross-platform plugins
│   └── template-plugin/
│       └── descriptor.json
├── ubuntu/               # Ubuntu-specific
│   ├── stat/
│   │   ├── descriptor.json
│   │   └── install.sh
│   └── apt-tool/
│       └── descriptor.json
├── alpine/               # Alpine Linux-specific
│   └── apk-tool/
└── macos/                # macOS-specific
    └── bsd-stat/
```

### Trade-offs Accepted

- **Duplication over Complexity**: Accept some plugin duplication for simplicity
- **Directory Structure over Inheritance**: Filesystem organization clearer than plugin hierarchy

---

## 9.5 ADR-005: Template-Based Report Generation

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Need mechanism to generate Markdown reports from analysis data

### Decision

Use simple Markdown templates with `{{variable}}` placeholder syntax. Substitute variables with workspace data during report generation.

### Rationale

**Strengths**:
- **User-Friendly**: Non-programmers can create/modify templates
- **Separation of Concerns**: Report structure separate from analysis logic
- **Customization**: Organizations can apply branding/standards
- **Version Control**: Plain text templates easily tracked
- **No Dependencies**: Simple string substitution in bash

**Weaknesses**:
- **Limited Logic**: No conditionals, loops, or complex expressions
- **Flat Namespace**: All variables in same scope
- **Error-Prone**: Typos in variable names fail silently

### Alternatives Considered

**Full Template Engine (Jinja2, Mustache)**:
- ✅ Powerful logic, conditionals, loops
- ❌ Requires additional runtime (Python, etc.)
- ❌ More complex for simple use case
- **Decision**: Overkill for needs, adds dependencies

**Embedded Scripting (Lua, etc.)**:
- ✅ Full programming in templates
- ❌ Too complex for report templates
- ❌ Security concerns (arbitrary code execution)
- **Decision**: Over-engineered, dangerous

**Markdown with Frontmatter**:
- ✅ Structured metadata section
- ❌ Still need variable substitution
- ❌ Doesn't solve core problem
- **Decision**: Could complement but doesn't replace

**Direct Code Generation**:
- ✅ Full control, type-safe
- ❌ Users can't customize without coding
- ❌ Violates separation of concerns
- **Decision**: Not user-friendly

### Implications

**Positive**:
- Users create templates in minutes
- No programming knowledge required
- Easy to preview (just Markdown)
- Can use any text editor

**Negative**:
- Cannot conditionally include sections
- Cannot iterate over arrays
- Limited formatting options

**Mitigation**:
- Provide multiple template examples
- Document available variables clearly
- Add helper functions for common formatting (dates, sizes)
- For complex needs, generate interim template then use external processor

### Template Example

```markdown
# Analysis Report: {{file_path}}

**Generated**: {{last_scanned}}

## File Information
- **Type**: {{file_type}}
- **Size**: {{file_size}}
- **Modified**: {{file_last_modified}}
- **Owner**: {{file_owner}}

## Content Analysis
{{content.summary}}

### Statistics
- **Word Count**: {{content.word_count}}
- **Line Count**: {{content.line_count}}

### Tags
{{content.tags}}
```

### Substitution Implementation

```bash
substitute_variables() {
  local template="$1"
  local -n data=$2  # Reference to associative array
  
  for key in "${!data[@]}"; do
    template="${template//\{\{${key}\}\}/${data[${key}]}}"
  done
  
  echo "${template}"
}
```

### Trade-offs Accepted

- **Simplicity over Power**: Accept limited templating for ease of use
- **String Replacement over Engine**: Avoid dependencies, keep it simple
- **User Customization over Code Generation**: Empower users to define output

---

## 9.6 ADR-006: No Agent System in Product Architecture

**Status**: Accepted  
**Date**: 2026-02-06  
**Context**: Project uses 6 agents (Developer, Tester, Architect, etc.) for development workflow

### Decision

Agent system is a **development process tool** for building doc.doc, not a feature of doc.doc itself. Agent architecture does NOT belong in product architecture documentation.

### Rationale

**Separation of Concerns**:
- **Product**: doc.doc.sh toolkit for file analysis
- **Process**: Agent-driven TDD workflow for developing doc.doc

**Product Architecture**:
- Documents **what we're building** (doc.doc toolkit)
- Covers CLI, plugins, orchestration, reporting
- Users run doc.doc, not agents

**Development Process**:
- Documents **how we build it** (agent workflow)
- Covers Developer→Tester→Architect coordination
- Contributors interact with agents, users don't

### Why This Matters

**If we included agents in product architecture**:
- ❌ Confuses users (they don't use agents)
- ❌ Mixes process with product
- ❌ Bloats architecture documentation
- ❌ Implies agents are runtime components

**Keeping them separate**:
- ✅ Clear focus: Architecture documents the product
- ✅ Process documented elsewhere (.github/agents/)
- ✅ Users understand doc.doc, contributors understand workflow
- ✅ Architecture remains relevant to end users

### Where Agent System IS Documented

**Appropriate Locations**:
- `AGENTS.md` - Agent registry
- `.github/agents/*.agent.md` - Agent definitions
- `.github/copilot-instructions.md` - Agent usage
- `02_agile_board/` - Development workflow

**Not Here**:
- `01_vision/03_architecture/` - Product architecture only

### Implications

- ✅ Architecture documentation focused on product
- ✅ Clear boundary: product vs development process
- ✅ Agent system can evolve without affecting product architecture
- ✅ Users not exposed to internal development tools

### Trade-offs Accepted

- **Product Focus over Process Documentation**: Architecture documents user-facing system
- **Clarity over Completeness**: Omit development tools from product architecture

---

## 9.7 Summary of Decisions

| ADR | Decision | Key Trade-off |
|-----|----------|---------------|
| **001** | Bash Implementation | Simplicity over sophistication |
| **002** | JSON Workspace | Human-readability over performance |
| **003** | Data-Driven Orchestration | Automation over explicit control |
| **004** | Platform-Specific Plugins | Duplication over complexity |
| **005** | Template-Based Reports | Simplicity over power |
| **006** | Agent System Exclusion | Product focus over process |

All decisions align with vision goals:
- ✅ Lightweight and simple
- ✅ Composable and extensible
- ✅ Local-first and secure
- ✅ User-friendly and accessible
- ✅ Standards-compliant (POSIX, JSON, Markdown)
