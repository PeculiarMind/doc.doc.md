# ADR-0003: Platform Detection Fallback Strategy

**Status**: ✅ Approved  
**Date**: 2026-02-06  
**Context**: Feature 0001 Implementation  
**Feature Reference**: [Feature 0001: Basic Script Structure](../../../01_vision/02_features/feature_0001.md)

## Decision

Implement three-tier platform detection: `/etc/os-release` → `uname -s` → "generic"

## Context

Platform detection must work across diverse environments:
- Modern Linux (has `/etc/os-release`)
- macOS (no `/etc/os-release`)
- Minimal containers (may lack `/etc/os-release`)
- BSDs, legacy systems

## Rationale

**Tier 1: `/etc/os-release`** (Primary):
- Standard on systemd-based Linux distributions
- Provides detailed information (ID, VERSION_ID, etc.)
- Most reliable for Linux platform-specific features

**Tier 2: `uname -s`** (Fallback):
- Universal availability on POSIX systems
- Provides basic OS identification
- Sufficient for high-level branching (Linux vs. Darwin)

**Tier 3: "generic"** (Default):
- Ensures script always has a platform value
- Enables graceful degradation of platform-specific features
- Prevents unset variable errors

## Implementation

```bash
detect_platform() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    PLATFORM="${ID:-generic}"  # Extract ID, fallback to generic
  else
    case "$(uname -s)" in
      Linux*)   PLATFORM="linux" ;;
      Darwin*)  PLATFORM="darwin" ;;
      CYGWIN*)  PLATFORM="cygwin" ;;
      MINGW*)   PLATFORM="mingw" ;;
      *)        PLATFORM="generic" ;;
    esac
  fi
  
  log "INFO" "Detected platform: ${PLATFORM}"
}
```

## Example Platform Values

| Environment | Detection | PLATFORM Value |
|-------------|-----------|----------------|
| Ubuntu | os-release | `ubuntu` |
| Debian | os-release | `debian` |
| Fedora | os-release | `fedora` |
| macOS | uname | `darwin` |
| Alpine (minimal) | os-release or uname | `alpine` or `linux` |
| Git Bash (Windows) | uname | `mingw` |
| Unknown | fallback | `generic` |

## Alternatives Considered

1. **Only uname**: Rejected - Less specific on Linux
2. **Only os-release**: Rejected - Breaks on macOS, older systems
3. **Complex detection (lsb_release, etc.)**: Rejected - Over-engineered, additional dependencies

## Impact

- **Portability**: Script runs on any POSIX system
- **Granularity**: Linux distributions identified specifically
- **Future Features**: Plugin discovery can check platform-specific directories (`plugins/ubuntu/`, `plugins/darwin/`)
- **Robustness**: Never fails platform detection (always has value)

## Implementation Location

**Code Reference**: `scripts/doc.doc.sh:113-130`

```bash
detect_platform() {
  if [[ -f /etc/os-release ]]; then
    # Tier 1: Parse /etc/os-release
    . /etc/os-release
    PLATFORM="${ID:-generic}"
  else
    # Tier 2: Fallback to uname
    case "$(uname -s)" in
      Linux*)   PLATFORM="linux" ;;
      Darwin*)  PLATFORM="darwin" ;;
      CYGWIN*)  PLATFORM="cygwin" ;;
      MINGW*)   PLATFORM="mingw" ;;
      *)        PLATFORM="generic" ;;  # Tier 3: Default
    esac
  fi
  
  log "INFO" "Detected platform: ${PLATFORM}"
}
```

**Implementation Date**: 2026-02-06  
**Feature**: feature_0001  
**Status**: ✅ Implemented and tested on Ubuntu
