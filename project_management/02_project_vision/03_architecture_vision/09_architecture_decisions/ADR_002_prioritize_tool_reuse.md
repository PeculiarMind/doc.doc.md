# Prioritize Reuse of Existing Tools Over Custom Implementation

- **ID:** ADR-002
- **Status:** DECIDED
- **Created at:** 2026-02-25
- **Created by:** Architect Agent
- **Decided at:** 2026-02-25
- **Decided by:** PeculiarMind
- **Obsoleted by:** N/A

# Change History
| Date | Author | Description |
|------|--------|-------------|
| 2026-02-25 | Architect Agent | Initial decision document created from REQ_0005 |

# TOC

1. [Context](#context)
2. [Decision](#decision)
3. [Consequences](#consequences)
4. [Alternatives Considered](#alternatives-considered)
5. [Evaluation Matrix](#evaluation-matrix)
6. [References](#references)

# Context

The doc.doc.md project is a command-line tool for document processing that requires various functionality including file system operations, MIME type detection, pattern matching, text processing, and more. When implementing these capabilities, there is a fundamental architectural choice: build custom implementations or leverage existing, proven tools and libraries.

## Project Goals

From [project_goals.md](../../01_project_goals/project_goals.md):
> "The tool prioritizes flexibility and customization while reusing existing tools wherever possible to avoid reinventing the wheel."

## Architectural Considerations

1. **Development Efficiency**: Time and effort required to implement, test, and debug functionality
2. **Reliability and Maturity**: Proven, battle-tested implementations vs. new custom code
3. **Maintenance Burden**: Ongoing maintenance, bug fixes, and feature updates
4. **Community Support**: Access to documentation, community knowledge, and updates
5. **Standardization**: Alignment with industry standards and practices
6. **Portability**: Cross-platform compatibility (Linux, macOS, potentially Windows)
7. **Performance**: Optimization and efficiency of implementations
8. **Security**: Vulnerability management and security updates

## Implementation Scenarios

The project faces numerous scenarios where this decision applies:

- **MIME type detection**: Could build custom magic number recognition vs. using standard `file` command
- **File system traversal**: Could implement custom directory walking vs. using `find` utility
- **Pattern matching**: Could build custom glob engine vs. using established libraries (e.g., Python's `pathlib`, `fnmatch`)
- **Text processing**: Could write custom parsers vs. using `grep`, `awk`, `sed`
- **JSON/YAML parsing**: Could implement custom parsers vs. using standard libraries
- **Template rendering**: Could build custom template engine vs. using established solutions

## Target Environment

The tool targets Unix/Linux environments with rich ecosystems of standard utilities and well-maintained libraries. Users are expected to have access to:
- Standard POSIX utilities (`find`, `grep`, `file`, etc.)
- Common package managers (apt, yum, brew)
- Established language ecosystems (Python PyPI, etc.)

# Decision

**We will prioritize reusing existing, proven tools and libraries over custom implementations** unless existing solutions are demonstrably inadequate for our requirements.

## Principles

1. **Default to Standard Unix/Linux Utilities**: Use POSIX-compliant tools (e.g., `find`, `file`, `grep`) for file system and text processing operations

2. **Leverage Well-Established Libraries**: Prefer mature, actively maintained libraries from language ecosystems (e.g., Python standard library, popular PyPI packages)

3. **Justify Custom Implementations**: Any decision to build custom functionality instead of using existing tools must be documented with clear technical justification including:
   - Specific inadequacies of existing tools
   - Performance, security, or functional requirements not met
   - Maintenance or licensing concerns
   - Rationale for why the custom implementation is superior

4. **Maintain Abstraction**: When using external tools, design interfaces that allow future replacement if needed

5. **Document Dependencies**: Clearly document all external tool and library dependencies with version requirements and installation instructions

## Application Examples

**Examples of Tool Reuse (Aligned with Decision):**
- Using `file` command for MIME type detection (via dedicated plugin)
- Using `find` for file system traversal
- Using Python's `pathlib` and `fnmatch` for glob pattern matching
- Using Python's `argparse` for command-line argument parsing
- Using Python's `json` module for descriptor parsing

**Examples Requiring Justification:**
- Building custom filtering logic combining AND/OR operators with multiple filter types (justified in ADR-001: Python chosen because shell's pattern matching insufficient for complex multi-criteria filtering)
- Custom plugin orchestration system (justified by need for cross-language plugin support with shell-based invocation)

# Consequences

## Positive

1. **Reduced Development Time**: Avoid reimplementing solved problems, focus effort on unique project value
2. **Higher Reliability**: Leverage battle-tested, widely-used implementations with years of bug fixes
3. **Better Security Posture**: Benefit from professional security audits and rapid vulnerability patching
4. **Lower Maintenance Burden**: Updates and improvements handled by upstream maintainers
5. **Community Support**: Access to extensive documentation, tutorials, and community knowledge
6. **Performance Benefits**: Many standard tools are highly optimized (e.g., `grep` in C vs. custom regex in shell)
7. **Industry Alignment**: Follow established patterns users already understand
8. **Faster Onboarding**: New contributors familiar with standard tools require less ramp-up time

## Negative

1. **External Dependencies**: Reliance on tools and libraries outside our control
2. **Version Compatibility**: Must manage compatibility across different tool/library versions
3. **Installation Complexity**: Users must install dependencies before using the tool
4. **Platform Variations**: Tools may behave differently across platforms (Linux vs. macOS vs. BSD)
5. **Learning Curve**: Team must understand multiple external tools rather than one custom codebase
6. **Limited Customization**: May need workarounds when external tools don't perfectly fit requirements
7. **Abstraction Overhead**: Must design interfaces to isolate dependencies for potential future replacement
8. **Licensing Constraints**: Must ensure all dependencies have compatible licenses

## Mitigation Strategies

- **Dependency Management**: Maintain clear dependency documentation with version requirements
- **Abstraction Layers**: Wrap external tools in interfaces to enable swapping if needed
- **Installation Scripts**: Provide automated dependency installation for common platforms
- **Compatibility Testing**: Test across Ubuntu, Debian, macOS to verify cross-platform behavior
- **License Audits**: Regular review of dependency licenses (see license.agent.md responsibility)
- **Fallback Mechanisms**: Where critical, implement graceful degradation if optional tools unavailable

# Alternatives Considered

## Alternative 1: Build Custom Implementations

**Approach**: Implement all functionality from scratch using only language primitives (Bash built-ins, Python standard library without external modules).

**Pros**:
- No external dependencies or installation requirements
- Complete control over behavior and features
- No version compatibility concerns
- Single unified codebase
- Platform-independent implementation

**Cons**:
- Significant development effort for already-solved problems
- Higher risk of bugs in new implementations
- Ongoing maintenance burden for custom code
- Missing optimizations from specialized tools (e.g., `grep` performance)
- Security vulnerabilities in custom implementations
- No community support or knowledge base
- Reinventing the wheel contrary to project goals

**Verdict**: ❌ Rejected — Contradicts project goals, inefficient use of development resources

## Alternative 2: Hybrid Approach (Selected Decision)

**Approach**: Prioritize existing tools, build custom only when justified.

**Pros**:
- Balance between reuse and flexibility
- Leverage existing tools for standard operations
- Custom code only where it adds unique value
- Documented justification for custom implementations
- Reduced development and maintenance effort

**Cons**:
- Requires dependency management
- Mixed architecture with both external and custom components
- Need to evaluate each functionality choice

**Verdict**: ✅ **Selected** — Best balance of efficiency, reliability, and flexibility

## Alternative 3: Full Framework Adoption

**Approach**: Build on top of existing document management framework or larger system (e.g., integrate with existing DMS, use Apache Tika, etc.).

**Pros**:
- Comprehensive feature set out of the box
- Professional support and extensive documentation
- Proven scalability

**Cons**:
- Heavy dependencies and resource requirements
- Loss of flexibility and customization
- Complexity exceeds project needs (targets home users, not enterprise)
- Steeper learning curve for contributors
- May require different architecture (web server, database, etc.)

**Verdict**: ❌ Rejected — Over-engineered for target use case, contradicts goal of lightweight tool for home users

# Evaluation Matrix

The following matrix compares all considered implementation approaches across key decision criteria:

| Criterion | Weight | Custom Implementations | Hybrid (Tool Reuse Priority) | Full Framework Adoption |
|-----------|--------|------------------------|------------------------------|-------------------------|
| **Development Efficiency** | 0.25 | ✗ High effort for solved problems | ✓ Focus on unique value | ~ Ready-made but complex |
| **Reliability & Maturity** | 0.20 | ✗ Unproven new code | ✓ Battle-tested tools | ✓ Enterprise-proven |
| **Maintenance Burden** | 0.20 | ✗ All code is our responsibility | ✓ Upstream handles most updates | ~ Framework updates complex |
| **Flexibility & Customization** | 0.15 | ✓ Complete control | ✓ Custom where needed | ✗ Framework constraints |
| **Alignment with Project Goals** | 0.10 | ✗ Contradicts "reuse" goal | ✓ Explicitly aligned | ✗ Too heavyweight |
| **Target User Fit** | 0.10 | ~ Simple but limited features | ✓ Right-sized for home users | ✗ Over-engineered |
| **Weighted Score** | **/1.0** | **0.15** (15%) | **0.95** (95%) | **0.30** (30%) |

**Legend:**
- ✓ = Strength / Good fit (1.0 point)
- ~ = Acceptable / Trade-off (0.5 points)
- ✗ = Weakness / Poor fit (0.0 points)

# References

- [Project Goals](../../01_project_goals/project_goals.md) — Source of "reuse existing tools" principle
- [ADR-001: Mixed Bash/Python Implementation](ADR_001_mixed_bash_python_implementation.md) — Examples of justified custom filtering logic
- Original Requirement: REQ_0005 (reclassified as architectural decision)
- Plugin System: Uses shell command invocation to support language-agnostic plugins while reusing standard command execution mechanisms
