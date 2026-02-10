#!/usr/bin/env bash
# Component: error_handling.sh
# Purpose: Error handling, exit code management, cleanup
# Dependencies: logging.sh
# Exports: error_exit(), handle_error(), cleanup(), set_exit_trap()
# Side Effects: Sets traps, modifies exit behavior

# ==============================================================================
# Error Handling Functions
# ==============================================================================

# Handle errors with context
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, defaults to EXIT_FILE_ERROR)
error_exit() {
  local message="$1"
  local exit_code="${2:-${EXIT_FILE_ERROR}}"
  
  log "ERROR" "ERROR" "${message}"
  exit "${exit_code}"
}

# Generic error handler (can be used as trap handler)
# Arguments:
#   $1 - Error message (optional)
handle_error() {
  local message="${1:-An error occurred}"
  log "ERROR" "ERROR" "${message}"
}

# Cleanup function (can be called on exit)
cleanup() {
  # Placeholder for cleanup operations
  log "DEBUG" "CLEANUP" "Cleanup called"
}

# Set exit trap for cleanup
set_exit_trap() {
  trap cleanup EXIT
}
