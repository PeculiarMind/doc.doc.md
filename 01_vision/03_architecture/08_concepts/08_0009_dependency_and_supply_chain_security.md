---
title: Dependency and Supply Chain Security Concept
arc42-chapter: 8
---

## 0009 Dependency and Supply Chain Security Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Dependency Model and Philosophy](#dependency-model-and-philosophy)
- [External Tool Dependencies](#external-tool-dependencies)
- [Tool Verification Approach](#tool-verification-approach)
- [Version Management Strategy](#version-management-strategy)
- [Supply Chain Risk Mitigation](#supply-chain-risk-mitigation)
- [Tool Substitution Attack Prevention](#tool-substitution-attack-prevention)
- [Update and Patching Strategy](#update-and-patching-strategy)
- [Secure Tool Invocation Patterns](#secure-tool-invocation-patterns)
- [Tool Availability Verification](#tool-availability-verification)
- [Risk Assessment for Dependency Failures](#risk-assessment-for-dependency-failures)
- [Integration with Other Concepts](#integration-with-other-concepts)
- [Related Requirements](#related-requirements)

Dependency and supply chain security manages the risks of relying on external CLI tools, ensuring tools are legitimate, up-to-date, and securely invoked to prevent command injection, tool substitution, and exploitation of vulnerable tool versions.

### Purpose

Dependency security:
- **Prevents Command Injection**: Secure tool invocation eliminates shell interpolation vulnerabilities
- **Blocks Tool Substitution**: Path validation prevents execution of malicious binaries
- **Mitigates Known Vulnerabilities**: Version verification rejects known-vulnerable tool versions
- **Ensures Tool Availability**: Pre-execution checks confirm tools exist and are functional
- **Maintains Security Posture**: Update strategy ensures security patches applied
- **Provides Flexibility**: Optional tools degrade gracefully without breaking core functionality

### Rationale

- **External Tool Reliance**: doc.doc.sh orchestrates CLI tools (git, exiftool, pandoc, stat, file, jq, etc.)
- **Bash Execution Context**: Shell scripting environment enables injection attacks if tools invoked insecurely
- **User Environments Vary**: Tool availability, versions, and locations differ across systems
- **Supply Chain Threats**: Compromised tools, malicious PATH entries, version-specific exploits
- **Offline Constraint**: No runtime network access to verify tool signatures or check for updates
- **Minimal Dependencies**: Prefer POSIX tools to reduce attack surface and installation burden

### Dependency Model and Philosophy

**Dependency Tiers**:

**Tier 1: Required Core Dependencies** (script fails if missing)
- `bash` (runtime environment, version 4.0+)
- `realpath` / `readlink` (path canonicalization, part of coreutils)
- `stat` (file metadata, part of coreutils)
- `file` (MIME type detection)
- `jq` (JSON parsing for plugin descriptors and workspace)

**Tier 2: Optional Analysis Tools** (features degrade if missing)
- `git` (VCS metadata extraction)
- `exiftool` (image/document EXIF data)
- `pandoc` (document format conversion)
- `pdfinfo` (PDF metadata)
- Platform-specific tools (varies by OS)

**Tier 3: Optional Enhancement Tools** (convenience only)
- `tree` (directory visualization)
- `wget` / `curl` (tool installation only, never runtime)

**Philosophy: Graceful Degradation**
- Core dependencies verified at startup (fail fast if missing)
- Optional tools checked before use (skip if unavailable, warn user)
- Plugin-specific tools checked per plugin (plugin skipped if tool missing)
- Clear error messages guide users to install missing tools
- No silent failures (always log tool unavailability)

**Philosophy: Minimal External Trust**
- Trust POSIX/coreutils (ubiquitous, well-audited)
- Distrust user-installed tools (verify before use)
- Distrust tool output (validate format, sanitize content)
- Prefer built-in Bash over external tools where secure (e.g., string manipulation)

### External Tool Dependencies

**Tool Dependency Inventory**:

| Tool | Purpose | Tier | Platform | Verification | Mitigation if Missing |
|------|---------|------|----------|--------------|----------------------|
| bash | Runtime environment | Core | All | Version check (4.0+) | Fail (cannot run) |
| realpath | Path canonicalization | Core | All | `command -v` | Fail (security critical) |
| stat | File metadata | Core | All | `command -v` | Fail (core functionality) |
| file | MIME type detection | Core | All | `command -v`, version | Fail (type validation) |
| jq | JSON parsing | Core | All | `command -v`, version | Fail (plugin system) |
| git | VCS metadata | Optional | All | `command -v`, version | Skip VCS analysis |
| exiftool | EXIF metadata | Optional | All | `command -v` | Skip EXIF extraction |
| pandoc | Document conversion | Optional | All | `command -v`, version | Skip format conversion |
| pdfinfo | PDF metadata | Optional | All | `command -v` | Skip PDF analysis |

**Plugin-Specific Dependencies** (discovered at runtime):
- Plugins declare dependencies in descriptor.json
- Plugin loading verifies tool availability (`check_commandline`)
- Plugin execution requires all dependencies present
- Missing plugin dependencies disable that plugin only (not entire system)

### Tool Verification Approach

**Multi-Layer Verification** (req_0053):

**Layer 1: Path Resolution** (prevent tool substitution)
```bash
verify_tool_path() {
    local tool_name="$1"
    
    # 1. Reject user-controlled paths (no absolute paths from CLI)
    # 2. Resolve via PATH environment variable only
    # 3. Use 'command -v' (POSIX-compliant, safe)
    # 4. Verify resolved path is executable
    # 5. Verify resolved path is regular file (not directory, symlink to directory)
    
    local tool_path
    tool_path=$(command -v "$tool_name" 2>/dev/null)
    
    if [[ -z "$tool_path" ]]; then
        log_security_error "Tool not found: $tool_name"
        return 1
    fi
    
    if [[ ! -x "$tool_path" ]]; then
        log_security_error "Tool not executable: $tool_path"
        return 1
    fi
    
    echo "$tool_path"
}
```

**Layer 2: Version Verification** (reject vulnerable versions)
```bash
verify_tool_version() {
    local tool_name="$1"
    local min_version="$2"
    local known_bad_versions="$3"  # Space-separated list
    
    # 1. Query tool version (--version, -v, -V depending on tool)
    # 2. Parse version string (handle different formats)
    # 3. Compare against minimum required version
    # 4. Check against known vulnerable versions
    # 5. Log version verification result
    
    local tool_version
    tool_version=$("$tool_name" --version 2>&1 | head -1)
    
    # Version compatibility check logic
    # If version too old or known vulnerable, reject
    
    log_security_info "Tool version verified: $tool_name $tool_version"
}
```

**Layer 3: Functional Verification** (tool works as expected)
```bash
verify_tool_functional() {
    local tool_name="$1"
    
    # 1. Run simple test command (tool-specific)
    # 2. Verify exit code is 0
    # 3. Verify output format matches expectations
    # 4. Timeout after reasonable duration (prevent hanging)
    
    # Example: jq test
    echo '{"test": "value"}' | jq -r '.test' &>/dev/null
    if [[ $? -ne 0 ]]; then
        log_security_error "Tool functional check failed: $tool_name"
        return 1
    fi
}
```

**Known Vulnerable Version Tracking**:
- Maintain list of known-bad tool versions (e.g., jq < 1.5, bash < 4.3)
- Check tool versions against vulnerability database (offline, bundled)
- Warn users about vulnerable versions (INFO/WARNING level)
- Optionally reject vulnerable versions (configurable, default: warn only)
- Update vulnerability list with toolkit releases

### Version Management Strategy

**Version Pinning Philosophy**: **Flexible Minimums, Not Strict Pins**

**Rationale**:
- Users control their system package versions (NAS, embedded systems)
- Strict version pins break on systems with different package repos
- Minimum version requirements ensure compatibility and security
- Users upgrade tools via system package manager (not toolkit-managed)

**Version Requirements**:
- **Minimum Required Version**: Oldest version with required features and without known critical vulnerabilities
- **Recommended Version**: Latest stable version for optimal security and features
- **Deprecated Versions**: Old versions with known vulnerabilities (warn user)

**Version Specification Examples**:
```bash
# In configuration or code
declare -A TOOL_MIN_VERSIONS=(
    [bash]="4.0"
    [jq]="1.5"
    [git]="2.0"
    [file]="5.0"
)

declare -A TOOL_RECOMMENDED_VERSIONS=(
    [bash]="5.0"
    [jq]="1.6"
    [git]="2.30"
    [file]="5.40"
)

declare -A TOOL_DEPRECATED_VERSIONS=(
    [bash]="<4.3"      # Shellshock vulnerability
    [jq]="<1.5"        # Various injection vulnerabilities
    [git]="<2.17.1"    # CVE-2018-11235
)
```

**Version Check Enforcement**:
- Core tools: Enforce minimum version (fail if below)
- Optional tools: Warn if below minimum (allow user override)
- All tools: Warn if deprecated version detected
- Verbose mode: Display all tool versions at startup

**Why Not Strict Pins**:
- ❌ Breaks on different Linux distributions (Ubuntu vs Alpine vs Debian)
- ❌ Prevents users from getting security updates via package manager
- ❌ Requires toolkit to manage tool installation (violates minimal dependency principle)
- ❌ Incompatible with offline-first design (no version registry to check)

### Supply Chain Risk Mitigation

**Risk: Compromised Tool Binaries**

**Mitigation Strategies**:
- PATH resolution only (no user-controlled absolute paths)
- Tool checksum verification (future: optional, if checksums bundled)
- Separate development and runtime environments (devcontainers vs user systems)
- System package manager trust (rely on OS package signatures)

**Risk: Malicious PATH Manipulation**

**Mitigation**:
```bash
# Sanitize PATH at script startup
sanitize_path() {
    # 1. Use system default PATH or explicit safe paths
    # 2. Remove current directory (.) from PATH
    # 3. Remove writable user directories from PATH (e.g., ~/bin before validation)
    # 4. Verify each PATH component is directory and readable
    
    export PATH="/usr/local/bin:/usr/bin:/bin"
    
    # Or preserve user PATH but sanitize
    local safe_path=""
    IFS=':' read -ra PATH_DIRS <<< "$PATH"
    for dir in "${PATH_DIRS[@]}"; do
        if [[ -d "$dir" && -r "$dir" && "$dir" != "." ]]; then
            safe_path="${safe_path}:${dir}"
        fi
    done
    export PATH="${safe_path#:}"
}
```

**Risk: Tool Substitution via LD_PRELOAD**

**Mitigation**:
```bash
# Unset dangerous environment variables
unset LD_PRELOAD
unset LD_LIBRARY_PATH
unset BASH_ENV
unset ENV
```

**Risk: Vulnerable Tool Versions**

**Mitigation**:
- Version verification (reject or warn)
- User notification (actionable error message with upgrade instructions)
- Security advisory references (link to CVE, security bulletin)
- Fallback to alternative tools (if available, e.g., gawk vs awk)

### Tool Substitution Attack Prevention

**Attack Vector**: Malicious binary masquerading as legitimate tool via PATH manipulation

**Prevention Mechanisms**:

**1. PATH Sanitization**
- Remove current directory (.) from PATH
- Use explicit safe PATH or validate user PATH components
- Check PATH components are not writable by non-root users

**2. Absolute Path Resolution**
- Resolve tool via `command -v` once at startup
- Store absolute paths in variables (avoid repeated PATH lookups)
- Use absolute paths for all tool invocations

**3. Tool Integrity Verification** (future enhancement)
- Checksum verification against known-good values
- Digital signature verification (if OS supports, e.g., macOS codesign)
- File permissions check (owned by root or trusted user)

**4. Execution Environment Control**
- Unset LD_PRELOAD, LD_LIBRARY_PATH (prevent library injection)
- Set IFS explicitly (prevent word splitting attacks)
- Use bash strict mode (set -euo pipefail)

**Example Secure Tool Execution**:
```bash
# Insecure (vulnerable to PATH manipulation)
jq -r '.name' file.json

# Secure (absolute path, validated)
declare -r JQ_PATH="/usr/bin/jq"  # Resolved and verified at startup
"$JQ_PATH" -r '.name' file.json
```

### Update and Patching Strategy

**User-Managed Tool Updates** (not toolkit-managed):
- Users update tools via system package manager (apt, yum, apk, brew)
- Toolkit detects new versions on next run (version check)
- Toolkit warns if deprecated versions still in use

**Toolkit Update Communication**:
- Release notes include tool version recommendations
- Security advisories published for critical tool vulnerabilities
- CHANGELOG documents tool version requirement changes

**Installation Guidance** (req_0008):
- Missing tool error messages include installation commands
- Platform-specific installation instructions (apt-get, yum, apk add, brew install)
- Links to official tool documentation

**Example Error Message**:
```
ERROR: Required tool 'jq' not found
  jq is required for JSON parsing (plugin descriptors, workspace data)
  
  Installation:
    Ubuntu/Debian: sudo apt-get install jq
    Alpine Linux:  sudo apk add jq
    macOS:         brew install jq
    
  Minimum version: 1.5
  Recommended:     1.6+
  
  For more information: https://stedolan.github.io/jq/
```

### Secure Tool Invocation Patterns

**Array-Based Execution** (prevent shell interpolation):
```bash
# INSECURE - vulnerable to command injection
tool_output=$(eval "$tool_command $user_input")

# SECURE - array-based execution
declare -a tool_cmd=("$TOOL_PATH" "$validated_arg1" "$validated_arg2")
tool_output=$("${tool_cmd[@]}")
```

**Argument Validation Before Invocation**:
```bash
invoke_tool() {
    local tool_path="$1"
    shift
    local -a args=("$@")
    
    # 1. Validate tool path (absolute, executable, exists)
    # 2. Validate each argument (format, length, no injection patterns)
    # 3. Sanitize arguments (quote, escape if needed)
    # 4. Execute with array (no shell interpolation)
    # 5. Capture stdout, stderr separately
    # 6. Validate exit code
    # 7. Sanitize output before use
    # 8. Log invocation (sanitized command line)
    
    for arg in "${args[@]}"; do
        if [[ "$arg" =~ [';|&$`(){}] ]]; then
            log_security_error "Invalid characters in tool argument: $arg"
            return 1
        fi
    done
    
    local tool_output
    tool_output=$("$tool_path" "${args[@]}" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_security_warning "Tool invocation failed: $tool_path (exit code: $exit_code)"
        return $exit_code
    fi
    
    echo "$tool_output"
}
```

**Environment Variable Control**:
```bash
# Set clean environment for tool execution
run_tool_clean_env() {
    local tool_path="$1"
    shift
    
    env -i \
        PATH="$SAFE_PATH" \
        HOME="$HOME" \
        USER="$USER" \
        LC_ALL=C \
        "$tool_path" "$@"
}
```

**Timeout and Resource Limits**:
```bash
# Prevent tool hanging or resource exhaustion
run_tool_with_limits() {
    local tool_path="$1"
    local timeout_seconds="$2"
    shift 2
    
    # Use timeout command or bash timeout
    timeout "$timeout_seconds" "$tool_path" "$@"
    
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        log_security_error "Tool exceeded timeout: $tool_path ($timeout_seconds seconds)"
        return 1
    fi
    
    return $exit_code
}
```

### Tool Availability Verification

**Pre-Execution Verification** (req_0007):
```bash
verify_required_tools() {
    local -a required_tools=(bash realpath stat file jq)
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
            log_error "Required tool not found: $tool"
        else
            # Verify version if applicable
            verify_tool_version "$tool"
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        print_installation_instructions "${missing_tools[@]}"
        exit 1
    fi
}

verify_optional_tools() {
    local -a optional_tools=(git exiftool pandoc pdfinfo)
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_warning "Optional tool not available: $tool (some features disabled)"
        else
            log_info "Optional tool available: $tool"
        fi
    done
}
```

**Plugin Tool Verification** (per-plugin):
```bash
verify_plugin_tools() {
    local plugin_descriptor="$1"
    
    # Extract tool requirements from plugin descriptor
    local required_tool
    required_tool=$(jq -r '.check_commandline' "$plugin_descriptor")
    
    # Execute check_commandline from descriptor
    if ! eval "$required_tool"; then
        log_warning "Plugin tool check failed: $plugin_descriptor"
        return 1
    fi
    
    return 0
}
```

### Risk Assessment for Dependency Failures

**Impact of Missing Core Tools**: **CRITICAL**
- Toolkit cannot function without core tools
- Fail fast with clear error message
- User must install missing tools before proceeding

**Impact of Missing Optional Tools**: **MEDIUM**
- Features degrade gracefully (skip unavailable analysis)
- User warned about missing functionality
- Alternative tools used if available (e.g., git vs manual file listing)

**Impact of Vulnerable Tool Versions**: **HIGH to CRITICAL**
- Known exploits may be present (command injection, arbitrary code execution)
- Warning issued to user with upgrade instructions
- Optionally reject vulnerable versions (configurable)

**Impact of Tool Substitution Attack**: **CRITICAL**
- Malicious binary executes with script privileges
- Could exfiltrate data, modify files, execute arbitrary code
- Mitigated by PATH sanitization and integrity verification

**Impact of Command Injection via Tool Arguments**: **CRITICAL**
- Arbitrary command execution in script context
- Full compromise of user session
- Mitigated by array-based execution and argument validation

**Dependency Failure Matrix**:

| Dependency Issue | Severity | Detection | Mitigation | User Impact |
|------------------|----------|-----------|------------|-------------|
| Missing core tool | CRITICAL | Startup check | Fail with install instructions | Cannot run |
| Missing optional tool | MEDIUM | Pre-use check | Skip feature, warn user | Reduced functionality |
| Vulnerable version | HIGH | Version check | Warn + upgrade instructions | Continue with risk |
| Tool substitution | CRITICAL | PATH sanitization, integrity | Reject malicious tools | Prevented attack |
| Command injection | CRITICAL | Argument validation, array exec | Reject dangerous args | Prevented attack |
| Tool timeout | LOW | Timeout wrapper | Terminate, log, continue | Skip slow operation |

### Integration with Other Concepts

**Security Architecture (08_0007)**:
- Dependency security is Layer 7 of defense-in-depth
- Tool invocation is critical trust boundary
- Secure tool patterns enforce security principles

**Input Validation and Security (08_0005)**:
- Tool arguments validated like all user inputs
- Path validation applies to tool paths
- Sanitization prevents injection via tool invocation

**Plugin Architecture (08_0001)**:
- Plugins declare tool dependencies in descriptor
- Plugin tool verification before execution
- Plugin-specific tools isolated to plugin scope

**Audit and Logging (08_0008)**:
- Tool verification logged (found, version, functional check)
- Tool invocation logged (sanitized command line)
- Tool failures logged (exit codes, stderr)

**Platform Support (08_0006)**:
- Tool availability varies by platform
- Platform-specific tool paths and versions
- Fallback tools for cross-platform compatibility

**Modular Script Architecture (08_0004)**:
- Tool verification module separated from usage
- Tool invocation abstraction (secure-by-default wrapper)
- Dependency injection (tools provided, not hardcoded)

### Related Requirements

**Core Dependency Requirements**:
- **req_0007**: [Tool Availability Verification](../../02_requirements/03_accepted/req_0007_tool_availability_verification.md)
- **req_0008**: [Installation Prompts](../../02_requirements/03_accepted/req_0008_installation_prompts.md)

**Security Requirements**:
- **req_0053**: [Dependency Tool Security Verification](../../02_requirements/01_funnel/req_0053_dependency_tool_security_verification.md) - comprehensive tool security
- **req_0038**: [Input Validation and Sanitization](../../02_requirements/03_accepted/req_0038_input_validation_and_sanitization.md) - argument validation
- **req_0051**: [Security Logging and Audit Trail](../../02_requirements/01_funnel/req_0051_security_logging_and_audit_trail.md) - tool verification logging

**Supporting Requirements**:
- **req_0009**: [Lightweight Implementation](../../02_requirements/03_accepted/req_0009_lightweight_implementation.md) - minimal dependencies
- **req_0010**: [Unix Tool Composability](../../02_requirements/03_accepted/req_0010_unix_tool_composability.md) - leverage existing tools
- **req_0015**: [Minimal Runtime Dependencies](../../02_requirements/03_accepted/req_0015_minimal_runtime_dependencies.md) - dependency philosophy
