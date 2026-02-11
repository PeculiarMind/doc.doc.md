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

# Component: mode_detection.sh
# Purpose: Detect interactive vs non-interactive execution mode
# Dependencies: logging.sh
# Exports: detect_interactive_mode(), IS_INTERACTIVE variable
# Side Effects: Sets global IS_INTERACTIVE variable

# ==============================================================================
# Global Mode State
# ==============================================================================
IS_INTERACTIVE=false

# ==============================================================================
# Mode Detection Functions
# ==============================================================================

# Detect whether script is running in interactive mode
# Interactive mode requires both stdin and stdout to be terminals
# Can be overridden with DOC_DOC_INTERACTIVE environment variable
# Side Effects:
#   Sets global IS_INTERACTIVE variable (true/false)
#   Exports IS_INTERACTIVE for use by child processes
detect_interactive_mode() {
  # Check for environment variable override first
  if [[ -n "${DOC_DOC_INTERACTIVE:-}" ]]; then
    IS_INTERACTIVE="${DOC_DOC_INTERACTIVE}"
    log "DEBUG" "INIT" "Interactive mode forced via environment: ${IS_INTERACTIVE}"
    export IS_INTERACTIVE
    return
  fi
  
  # Auto-detect based on terminal attachment
  # Both stdin (fd 0) and stdout (fd 1) must be terminals for interactive mode
  if [ -t 0 ] && [ -t 1 ]; then
    IS_INTERACTIVE=true
    log "DEBUG" "INIT" "Running in interactive mode (terminal detected)"
  else
    IS_INTERACTIVE=false
    log "DEBUG" "INIT" "Running in non-interactive mode (no terminal)"
  fi
  
  # Export for use by child processes
  export IS_INTERACTIVE
}
