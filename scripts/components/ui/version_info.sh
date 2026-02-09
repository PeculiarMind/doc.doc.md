#!/usr/bin/env bash
# Component: version_info.sh
# Purpose: Version display
# Dependencies: core/constants.sh
# Exports: show_version()
# Side Effects: None (pure display)

# ==============================================================================
# Version Information Functions
# ==============================================================================

# Display version information
show_version() {
  cat <<EOF
${SCRIPT_NAME} version ${SCRIPT_VERSION}
${SCRIPT_COPYRIGHT}
License: ${SCRIPT_LICENSE}

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
}
