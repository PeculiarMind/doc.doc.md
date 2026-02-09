# Requirement: Platform Support Definition

**ID**: req_0033

## Status
State: Accepted  
Created: 2026-02-09  
Last Updated: 2026-02-09

## Overview
The system shall explicitly define supported platforms and provide platform-specific plugin loading to accommodate tool differences across operating systems and Linux distributions.

## Description
The toolkit must clearly document which platforms are supported and to what extent. ADR-0004 defines platform-specific plugin directories (`plugins/ubuntu/`, `plugins/all/`, etc.) to handle tool availability and command-line flag differences across platforms. However, there is no requirement explicitly stating which platforms are officially supported, what level of testing and maintenance each receives, and how platform detection works. The system must detect the runtime platform, load appropriate platform-specific plugins with precedence over generic plugins, and gracefully handle unsupported platforms by running with available cross-platform plugins only.

## Motivation
From ADR-0004: "Organize plugins in platform-specific directories (`plugins/ubuntu/`, `plugins/macos/`, `plugins/all/`). System detects platform at runtime and loads appropriate plugins with precedence: platform-specific over generic."

From vision: "Stay composable by integrating with common Linux tools" and development container goals mention "Ubuntu, Debian, Arch, generic Linux."

Without explicit platform support definition, users cannot determine if their environment is supported, and contributors don't know which platforms to test. Platform detection and plugin loading logic is architectural but needs a requirement to ensure it's implemented correctly and documented.

## Category
- Type: Non-Functional (Portability)
- Priority: Medium

## Acceptance Criteria

### Supported Platforms
- [ ] Documentation explicitly lists supported platforms with support tiers:
  - Tier 1 (Primary Support): Ubuntu LTS, Debian Stable
  - Tier 2 (Secondary Support): Arch Linux, Generic Linux
  - Tier 3 (Best Effort): Other POSIX-compliant systems
- [ ] Each tier defines support expectations (testing, bug fixes, feature parity)
- [ ] Minimum required Bash version documented for each platform
- [ ] Known unsupported platforms documented with rationale

### Platform Detection
- [ ] The system automatically detects runtime platform on startup
- [ ] Detection uses reliable methods (e.g., `/etc/os-release`, `uname`)
- [ ] Detected platform is logged in verbose mode
- [ ] Detection failure results in fallback to "generic" platform mode
- [ ] Platform detection completes in < 1 second

### Plugin Loading Precedence
- [ ] System loads platform-specific plugins from `plugins/<platform>/` first
- [ ] Cross-platform plugins from `plugins/all/` loaded as fallback
- [ ] Plugin with same name in platform directory overrides generic version
- [ ] Plugin loading precedence clearly documented
- [ ] Missing platform directory doesn't cause errors (uses generic plugins)

### Graceful Degradation
- [ ] Unsupported platforms run with generic plugins only
- [ ] Missing platform-specific plugins log warning but don't halt execution
- [ ] Clear message explains reduced functionality on unsupported platforms
- [ ] System never crashes due to platform incompatibility

### Cross-Platform Compatibility
- [ ] Core functionality works on all Tier 1 and Tier 2 platforms
- [ ] Platform-specific plugins documented with platform requirements
- [ ] Testing performed on at least Ubuntu LTS and Debian Stable
- [ ] Platform differences (tool flags, paths) isolated to plugins, not core

### Documentation
- [ ] README clearly states supported platforms and tiers
- [ ] Installation instructions specific to each Tier 1 platform
- [ ] Contributing guide explains how to add new platform support
- [ ] Plugin development guide explains platform-specific plugin creation

## Related Requirements
- req_0009 (Lightweight Implementation) - platform support doesn't add heavy dependencies
- req_0010 (Unix Tool Composability) - composability across different UNIX-like platforms
- req_0022 (Plugin-based Extensibility) - platform-specific plugins extend core
- req_0026 (Development Containers) - devcontainers match supported platforms

## Technical Considerations

### Platform Detection Script
```bash
detect_platform() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            ubuntu) echo "ubuntu" ;;
            debian) echo "debian" ;;
            arch) echo "arch" ;;
            *) echo "generic" ;;
        esac
    else
        echo "generic"
    fi
}
```

### Plugin Directory Structure
```
plugins/
├── all/                    # Cross-platform (Tier 1, 2, 3)
│   └── basic-metadata/
├── ubuntu/                 # Ubuntu-specific (Tier 1)
│   └── apt-info/
├── debian/                 # Debian-specific (Tier 1)
│   └── dpkg-info/
├── arch/                   # Arch-specific (Tier 2)
│   └── pacman-info/
└── generic/                # Fallback (Tier 3)
    └── minimal-metadata/
```

### Support Tier Definitions
- **Tier 1**: Automated testing, regular bug fixes, feature parity guaranteed
- **Tier 2**: Manual testing, bug fixes on best-effort, most features available
- **Tier 3**: Community-supported, no guarantees, basic functionality only

## Transition History
- [2026-02-09] Created and placed in Funnel by Requirements Engineer Agent  
-- Comment: ADR-0004 defines architecture, but requirement needed for implementation and documentation
- [2026-02-09] Moved to Accepted by user  
-- Comment: Accepted as platform compatibility requirement
