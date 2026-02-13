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

# Component: template_display.sh
# Purpose: Template listing and formatting
# Dependencies: core/logging.sh
# Exports: list_templates(), display_template_list()
# Side Effects: None (pure formatting, outputs to stdout)

# ==============================================================================
# Template Display Functions
# ==============================================================================

# Display formatted template list
# Arguments:
#   $@ - Array of template data strings (name|path|description)
display_template_list() {
  local -a templates=("$@")
  
  if [[ ${#templates[@]} -eq 0 ]]; then
    echo "No templates found in templates directory."
    echo
    echo "Templates directory: scripts/templates/"
    return
  fi
  
  echo "Available Templates:"
  echo "===================================="
  echo
  
  # Sort templates by name
  local -a sorted_templates
  IFS=$'\n' sorted_templates=($(sort <<<"${templates[*]}"))
  unset IFS
  
  # Display each template
  for template_data in "${sorted_templates[@]}"; do
    # Parse pipe-delimited data
    local name="${template_data%%|*}"
    local rest="${template_data#*|}"
    local path="${rest%%|*}"
    local description="${rest##*|}"
    
    # Truncate description if too long
    if [[ ${#description} -gt 80 ]]; then
      description="${description:0:77}..."
    fi
    
    # Check if this is the default template
    local default_marker=""
    if [[ "${name}" == "default" ]]; then
      default_marker=" [DEFAULT]"
    fi
    
    # Display template info
    printf "%s%s\n" "${name}" "${default_marker}"
    printf "  Path: %s\n" "${path}"
    if [[ -n "${description}" ]]; then
      printf "  Description: %s\n" "${description}"
    fi
    printf "\n"
  done
  
  echo "===================================="
  echo "To use a template:"
  echo "  ${SCRIPT_NAME} -d <directory> -m <template-path> -t <output>"
  echo
  echo "Or use the default template by omitting -m:"
  echo "  ${SCRIPT_NAME} -d <directory> -t <output>"
}

# Extract description from template file
# Arguments:
#   $1 - Template file path
# Returns:
#   Description string (first comment or empty)
extract_template_description() {
  local template_file="$1"
  local description=""
  
  # Try to extract description from first few lines
  # Look for HTML comments or leading text
  if [[ -f "${template_file}" ]]; then
    # Get first non-empty line as description (simplified)
    description=$(head -n 5 "${template_file}" | grep -v '^#' | grep -v '^$' | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # If first line is a heading, use it as description
    if [[ -z "${description}" ]]; then
      description=$(head -n 1 "${template_file}" | sed 's/^#*[[:space:]]*//')
    fi
  fi
  
  echo "${description}"
}

# Discover and list all available templates
list_templates() {
  log "INFO" "TEMPLATE" "Listing available templates"
  
  # Determine templates directory
  local templates_dir="${SCRIPT_DIR}/templates"
  
  if [[ ! -d "${templates_dir}" ]]; then
    echo "Templates directory not found: ${templates_dir}"
    echo
    echo "Expected location: scripts/templates/"
    return 1
  fi
  
  # Discover template files
  local -a templates=()
  
  # Find all .md files except README.md
  while IFS= read -r -d '' template_file; do
    local filename=$(basename "${template_file}")
    
    # Skip README files
    if [[ "${filename}" == "README.md" ]]; then
      continue
    fi
    
    # Extract template name (filename without extension)
    local template_name="${filename%.md}"
    
    # Extract description
    local description=$(extract_template_description "${template_file}")
    
    # Add to templates array: name|path|description
    templates+=("${template_name}|${template_file}|${description}")
  done < <(find "${templates_dir}" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
  
  # Display template list
  display_template_list "${templates[@]}"
}
