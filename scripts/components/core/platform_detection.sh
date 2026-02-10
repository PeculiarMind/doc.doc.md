#!/usr/bin/env bash
# Copyright (c) 2026 doc.doc.md Project
# This file is part of doc.doc.md.
#
# doc.doc.md is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# doc.doc.md is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with doc.doc.md. If not, see <https://www.gnu.org/licenses/>.

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
