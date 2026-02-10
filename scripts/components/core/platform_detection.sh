#!/usr/bin/env bash
# Component: platform_detection.sh
# Purpose: Platform detection (ubuntu, debian, darwin, etc.)
# Dependencies: logging.sh
# Exports: detect_platform(), PLATFORM variable
# Side Effects: Sets global PLATFORM variable

# ==============================================================================
# Global Platform State
# ==============================================================================
PLATFORM="generic"

# ==============================================================================
# Platform Detection Functions
# ==============================================================================

# Detect the current platform
# Side Effects:
#   Sets global PLATFORM variable
detect_platform() {
  if [[ -f /etc/os-release ]]; then
    # Source the os-release file to get distribution info
    . /etc/os-release
    PLATFORM="${ID:-generic}"
  else
    # Fallback to uname if os-release is not available
    case "$(uname -s)" in
      Linux*)   PLATFORM="linux" ;;
      Darwin*)  PLATFORM="darwin" ;;
      CYGWIN*)  PLATFORM="cygwin" ;;
      MINGW*)   PLATFORM="mingw" ;;
      *)        PLATFORM="generic" ;;
    esac
  fi
  
  log "INFO" "PLATFORM" "Detected platform: ${PLATFORM}"
}
