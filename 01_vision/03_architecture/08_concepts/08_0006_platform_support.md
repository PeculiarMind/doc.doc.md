---
title: Platform Support Concept
arc42-chapter: 8
---

## 0006 Platform Support Concept

## Table of Contents

- [Purpose](#purpose)
- [Rationale](#rationale)
- [Support Tiers](#support-tiers)
- [Platform Detection](#platform-detection)
- [Plugin Loading Strategy](#plugin-loading-strategy)
- [Graceful Degradation](#graceful-degradation)
- [Testing Strategy](#testing-strategy)
- [Related Requirements](#related-requirements)

Platform support establishes explicit tiers of supported operating systems and defines how the toolkit detects platforms and loads appropriate plugins.

### Purpose

Platform support:
- **Defines Support Levels**: Clear expectations for which platforms are officially supported
- **Enables Platform Optimization**: Platform-specific plugins use native tools
- **Ensures Compatibility**: Core functionality works across all supported platforms
- **Guides Testing**: Prioritizes testing effort based on support tier
- **Manages Expectations**: Users know what level of support to expect

### Rationale

- **Tool Availability Varies**: Different platforms have different CLI tools available
- **Flag Differences**: Same tools have different flags across platforms (GNU vs BSD)
- **Path Conventions**: File paths and system directories differ
- **Package Managers**: Installation instructions differ by platform
- **Resource Constraints**: Limited testing resources require prioritization

### Support Tiers

#### Tier 1: Primary Support (Full Support)

**Platforms**:
- **Ubuntu LTS** (20.04, 22.04, 24.04)
- **Debian Stable** (11, 12)

**Characteristics**:
- Full feature parity
- Comprehensive testing (automated CI + manual)
- All plugins tested and validated
- Development containers provided
- Installation guides and examples
- Bug fixes prioritized
- Performance optimization
- Security patches within 48 hours

**Guarantees**:
- ✅ All core functionality works
- ✅ All official plugins available
- ✅ Regular testing in CI pipeline
- ✅ Complete documentation
- ✅ Timely bug fixes and updates

#### Tier 2: Secondary Support (Community Support)

**Platforms**:
- **Arch Linux** (rolling release)
- **Fedora** (latest stable)
- **Generic Linux** (POSIX-compliant with Bash 4.3+)

**Characteristics**:
- Core functionality tested
- Platform-specific plugins may be limited
- Development containers may be provided
- Community contributions welcome
- Best-effort bug fixes
- Documentation may lag behind Tier 1

**Guarantees**:
- ✅ Core analysis workflow works
- ✅ Generic plugins functional
- ⚠️ Platform-specific plugins may be missing
- ⚠️ Bug fixes on best-effort basis
- ⚠️ Testing less comprehensive than Tier 1

#### Tier 3: Best Effort (Experimental)

**Platforms**:
- **macOS** (with Homebrew)
- **WSL** (Windows Subsystem for Linux)
- **Other POSIX-compliant** systems

**Characteristics**:
- Basic functionality may work
- Minimal testing
- No dedicated development containers
- Community-driven plugin development
- No guarantees on bug fixes
- "Use at your own risk"

**Guarantees**:
- ⚠️ May work with generic plugins only
- ⚠️ No official testing
- ⚠️ No dedicated support
- ✅ Contributions accepted
- ✅ Community feedback welcome

### Platform Detection

**Detection Strategy**:
```bash
detect_platform() {
    local platform="unknown"
    
    # Try /etc/os-release first (modern Linux standard)
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            ubuntu)
                platform="ubuntu"
                log_verbose "Detected platform: Ubuntu ${VERSION_ID}"
                ;;
            debian)
                platform="debian"
                log_verbose "Detected platform: Debian ${VERSION_ID}"
                ;;
            arch)
                platform="arch"
                log_verbose "Detected platform: Arch Linux"
                ;;
            fedora)
                platform="fedora"
                log_verbose "Detected platform: Fedora ${VERSION_ID}"
                ;;
            *)
                platform="generic"
                log_verbose "Detected platform: $ID (using generic plugins)"
                ;;
        esac
    
    # Fallback to uname for non-Linux or old systems
    elif [[ "$(uname)" == "Darwin" ]]; then
        platform="macos"
        log_verbose "Detected platform: macOS"
    
    elif [[ "$(uname -r)" =~ Microsoft ]]; then
        platform="wsl"
        log_verbose "Detected platform: Windows Subsystem for Linux"
    
    else
        platform="generic"
        log_warning "Could not detect platform, using generic plugins"
    fi
    
    # Export for use throughout script
    export DETECTED_PLATFORM="$platform"
    echo "$platform"
}
```

**Detection Sources** (in priority order):
1. `/etc/os-release` - Modern Linux standard (systemd-based)
2. `uname` output - Fallback for non-Linux or very old systems
3. WSL detection - Kernel version contains "Microsoft"
4. Fallback to "generic" if detection fails

**Detection Timing**:
- Performed once at script startup
- Cached in environment variable for subsequent use
- Logged in verbose mode for debugging

**Performance**:
- < 1 second detection time
- No network access required
- Minimal file I/O (read one file)

### Plugin Loading Strategy

**Loading Precedence**:
```
1. Platform-specific plugins   plugins/{detected_platform}/
2. Generic cross-platform      plugins/all/
```

**Plugin Resolution Algorithm**:
```bash
load_plugins() {
    local plugin_base_dir="$1"
    local platform="$2"
    local plugins=()
    
    # Load platform-specific plugins first
    local platform_dir="${plugin_base_dir}/${platform}"
    if [[ -d "$platform_dir" ]]; then
        log_verbose "Loading $platform-specific plugins from: $platform_dir"
        for descriptor in "$platform_dir"/*/descriptor.json; do
            [[ -f "$descriptor" ]] || continue
            plugins+=("$descriptor")
        done
    else
        log_verbose "No platform-specific directory found: $platform_dir"
    fi
    
    # Load generic plugins
    local generic_dir="${plugin_base_dir}/all"
    if [[ -d "$generic_dir" ]]; then
        log_verbose "Loading generic plugins from: $generic_dir"
        for descriptor in "$generic_dir"/*/descriptor.json; do
            [[ -f "$descriptor" ]] || continue
            
            # Extract plugin name
            local plugin_name=$(jq -r '.name' "$descriptor")
            
            # Skip if platform-specific version already loaded
            local skip=false
            for loaded_plugin in "${plugins[@]}"; do
                local loaded_name=$(jq -r '.name' "$loaded_plugin")
                if [[ "$loaded_name" == "$plugin_name" ]]; then
                    log_verbose "Skipping generic $plugin_name (platform version loaded)"
                    skip=true
                    break
                fi
            done
            
            [[ "$skip" == "true" ]] || plugins+=("$descriptor")
        done
    fi
    
    printf '%s\n' "${plugins[@]}"
}
```

**Override Logic**:
- Plugin name extracted from descriptor.json
- If plugin with same name exists in both `platform/` and `all/`, use platform version
- Generic version logged as skipped in verbose mode
- Allows platform-specific optimizations without breaking generic support

**Example Scenario**:
```
plugins/
├── all/
│   └── stat/                  # Generic stat plugin (POSIX stat)
│       └── descriptor.json
└── ubuntu/
    └── stat/                  # Ubuntu-optimized (GNU stat with more flags)
        └── descriptor.json

On Ubuntu:    uses ubuntu/stat/  (platform-specific)
On Debian:    uses ubuntu/stat/  (shares Ubuntu approach)
On Arch:      uses all/stat/     (generic fallback)
```

### Graceful Degradation

**Principles**:
- **Never Crash**: Unsupported platform uses generic plugins
- **Clear Communication**: Log platform detection and plugin loading
- **Functionality Preservation**: Core features work everywhere
- **Helpful Guidance**: Explain reduced functionality on unsupported platforms

**Degradation Behaviors**:

```bash
handle_unsupported_platform() {
    local platform="$1"
    
    log_warning "Platform '$platform' is not fully supported (Tier 3)"
    log_info "Falling back to generic cross-platform plugins"
    log_info "Some features may be limited or unavailable"
    log_info "See documentation for platform support details"
    
    # Continue with generic plugins
    load_plugins "$PLUGIN_DIR" "all"
}

handle_missing_tool() {
    local tool_name="$1"
    local plugin_name="$2"
    
    log_warning "Tool '$tool_name' not found for plugin '$plugin_name'"
    log_info "Plugin will be skipped for this analysis"
    log_info "Install $tool_name to enable this functionality"
    
    # Provide installation hint based on platform
    case "$DETECTED_PLATFORM" in
        ubuntu|debian)
            log_info "Hint: sudo apt install $tool_name"
            ;;
        arch)
            log_info "Hint: sudo pacman -S $tool_name"
            ;;
        fedora)
            log_info "Hint: sudo dnf install $tool_name"
            ;;
        macos)
            log_info "Hint: brew install $tool_name"
            ;;
    esac
}
```

**Fallback Strategy**:
1. Detect platform
2. Attempt to load platform-specific plugins
3. If platform directory missing → use `all/` plugins
4. If platform tool unavailable → skip plugin, continue with others
5. Log all fallbacks clearly for user awareness

### Testing Strategy

**Tier 1 Testing (Ubuntu, Debian)**:
- Automated CI pipeline on every commit
- Full test suite: unit, integration, system tests
- All plugins tested in CI environment
- Development container testing
- Performance benchmarking
- Manual exploratory testing before releases

**Tier 2 Testing (Arch, Generic Linux)**:
- Manual testing before major releases
- Community feedback incorporated
- Development container testing (if available)
- Core functionality verified
- Plugin subset tested

**Tier 3 Testing (macOS, WSL)**:
- Community-driven testing only
- No CI infrastructure
- Bug reports from community
- Best-effort verification by maintainers

**Test Matrix Example**:
```
Platform    | Core | Plugins | CI | Manual | Containers
------------|------|---------|----|---------|-----------
Ubuntu LTS  |  ✅  |   ✅    | ✅ |   ✅   |    ✅
Debian      |  ✅  |   ✅    | ✅ |   ✅   |    ✅
Arch Linux  |  ✅  |   ⚠️    | ⚠️ |   ✅   |    ⚠️
Generic     |  ✅  |   ⚠️    | ❌ |   ⚠️   |    ❌
macOS       |  ⚠️  |   ❌    | ❌ |   ❌   |    ❌
WSL         |  ⚠️  |   ❌    | ❌ |   ❌   |    ❌
```

### Platform-Specific Considerations

**Ubuntu/Debian (Tier 1)**:
- GNU coreutils available (stat, find, grep with GNU flags)
- apt package manager for tool installation
- Standard FHS (Filesystem Hierarchy Standard) paths
- systemd for service management (if needed)

**Arch Linux (Tier 2)**:
- Rolling release model (always recent versions)
- pacman package manager
- May have newer tools than Ubuntu LTS
- Community-maintained plugins welcome

**macOS (Tier 3)**:
- BSD userland (different flags than GNU)
- Homebrew for package management
- Case-insensitive filesystem by default
- Limited testing support

**WSL (Tier 3)**:
- Linux kernel but Windows filesystem integration
- Path handling complexities (Windows paths)
- Performance considerations (cross-system I/O)
- Hybrid environment challenges

### Documentation Requirements

**Platform Documentation**:
- README clearly states supported platforms and tiers
- Installation guides per Tier 1 platform
- Platform-specific troubleshooting section
- Contributing guide explains how to add platform support
- Plugin development guide covers platform-specific plugins

**User Communication**:
- `-p list` shows platform detection result
- Verbose mode logs detected platform
- Unsupported platform displays clear warning
- Help text mentions supported platforms

### Related Requirements

- [req_0033: Platform Support Definition](../../02_requirements/03_accepted/req_0033_platform_support.md) - defines platform support requirement
- [req_0009: Lightweight Implementation](../../02_requirements/03_accepted/req_0009_lightweight_implementation.md) - platform support doesn't add heavy dependencies
- [req_0010: Unix Tool Composability](../../02_requirements/03_accepted/req_0010_unix_tool_composability.md) - composability across different UNIX-like platforms
- [req_0022: Plugin-based Extensibility](../../02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - platform-specific plugins extend core
- [req_0026: Development Containers](../../02_requirements/03_accepted/req_0026_development_containers.md) - devcontainers match supported platforms

### Related Architecture Decisions

- [ADR-0004: Platform-specific Plugin Directories](../09_architecture_decisions/ADR_0004_platform_specific_plugin_directories.md) - architectural foundation for platform support
