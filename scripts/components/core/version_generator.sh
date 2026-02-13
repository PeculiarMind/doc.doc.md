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

# Component: version_generator.sh
# Purpose: Generate semantic timestamp version strings per ADR-0012
# Dependencies: None
# Exports: generate_version_string(), validate_version_format()
# Side Effects: Reads from scripts/components/version_name.txt

# ==============================================================================
# Semantic Timestamp Versioning (ADR-0012)
# ==============================================================================
# Format: <YEAR>_<CREATIVE_NAME>_<MMDD>.<SECONDS_OF_DAY>
# Example: 2026_Phoenix_0213.54321

# Path to creative name file (single source of truth)
readonly VERSION_NAME_FILE="${SCRIPT_DIR}/components/version_name.txt"

# Generate version string using current timestamp
# Returns: Version string in format YYYY_NAME_MMDD.SECONDS
# Exit codes: 0 on success, 1 on error
generate_version_string() {
  # Read creative name from file
  if [[ ! -f "$VERSION_NAME_FILE" ]]; then
    echo "ERROR: Version name file not found: $VERSION_NAME_FILE" >&2
    return 1
  fi
  
  local creative_name
  creative_name=$(cat "$VERSION_NAME_FILE" | tr -d '\n' | tr -d '\r')
  
  # Validate creative name
  if [[ -z "$creative_name" ]]; then
    echo "ERROR: Creative name is empty in $VERSION_NAME_FILE" >&2
    return 1
  fi
  
  if ! [[ "$creative_name" =~ ^[A-Z][A-Za-z]*$ ]]; then
    echo "ERROR: Creative name must start with uppercase and contain only letters: $creative_name" >&2
    return 1
  fi
  
  # Generate timestamp components (UTC)
  local year=$(date -u +%Y)
  local mmdd=$(date -u +%m%d)
  local seconds_since_midnight=$(date -u +%s)
  local seconds_of_day=$((seconds_since_midnight % 86400))
  
  # Construct version string
  echo "${year}_${creative_name}_${mmdd}.${seconds_of_day}"
}

# Validate version format
# Arguments: $1 - Version string to validate
# Exit codes: 0 if valid, 1 if invalid
validate_version_format() {
  local version="$1"
  
  # Check basic format pattern
  if ! echo "$version" | grep -qE '^[0-9]{4}_[A-Z][A-Za-z]+_[0-9]{4}\.[0-9]+$'; then
    return 1
  fi
  
  # Extract components for semantic validation
  local year=$(echo "$version" | cut -d'_' -f1)
  local mmdd=$(echo "$version" | cut -d'_' -f3 | cut -d'.' -f1)
  local seconds=$(echo "$version" | cut -d'.' -f2)
  
  # Validate year (reasonable range)
  local year_int=$((10#$year))
  if [[ $year_int -lt 2000 || $year_int -gt 2100 ]]; then
    return 1
  fi
  
  # Validate month (01-12)
  local month=$(echo "$mmdd" | cut -c1-2)
  local month_int=$((10#$month))
  if [[ $month_int -lt 1 || $month_int -gt 12 ]]; then
    return 1
  fi
  
  # Validate day (01-31, simplified check)
  local day=$(echo "$mmdd" | cut -c3-4)
  local day_int=$((10#$day))
  if [[ $day_int -lt 1 || $day_int -gt 31 ]]; then
    return 1
  fi
  
  # Validate seconds of day (0-86399)
  local seconds_int=$((10#$seconds))
  if [[ $seconds_int -lt 0 || $seconds_int -gt 86399 ]]; then
    return 1
  fi
  
  return 0
}
