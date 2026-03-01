# Constraints

## Technical Constraints

| Constraint | Description | Rationale |
|------------|-------------|-----------|
| **TC-1: Unix/Linux Environment** | Primary target is Unix/Linux systems (Linux, macOS). Windows support via WSL/Git Bash only. | Leverages standard Unix utilities (find, file, grep) and shell scripting capabilities. Home-lab enthusiasts typically run Linux. |
| **TC-2: Bash as Primary Language** | Main orchestration and CLI interface implemented in Bash. | Aligns with Unix philosophy, provides direct access to system utilities, familiar to target users. See ADR-001. |
| **TC-3: Python for Complex Logic** | Complex filtering and data processing implemented in Python 3.7+. | Shell scripting inadequate for complex AND/OR filter logic and advanced pattern matching. See ADR-001. |
| **TC-4: Standard Unix Utilities** | Rely on POSIX-compliant utilities (find, file, grep, etc.). | Avoid reinventing the wheel, leverage proven tools. See ADR-002. |
| **TC-5: Minimal External Dependencies** | Minimize dependencies beyond standard Unix utilities and Python standard library. | Ensure easy installation and maintenance for home users. |
| **TC-6: Shell-Based Plugin Invocation** | Plugins invoked as shell commands, not direct language imports. | Enables language-agnostic plugin system while maintaining simple interface. |

## Organizational Constraints

| Constraint | Description |
|------------|-------------|
| **OC-1: Open Source** | Project must remain open source with permissive licensing. |
| **OC-2: Single Developer** | Initially maintained by single developer; architecture must be understandable by newcomers. |
| **OC-3: Documentation Requirements** | Comprehensive documentation required for users and plugin developers. |

## Conventions

| Convention | Description |
|------------|-------------|
| **CV-1: Arc42 Documentation** | Architecture documented using Arc42 template structure. |
| **CV-2: Markdown for All Docs** | All documentation in markdown format for accessibility and compatibility. |
| **CV-3: POSIX Compliance** | Shell scripts follow POSIX standards where possible for maximum compatibility. |
| **CV-4: Clear Naming** | Commands and options use descriptive names; both long and short parameter forms provided. |
