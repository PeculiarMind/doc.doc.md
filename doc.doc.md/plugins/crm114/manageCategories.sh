#!/bin/bash
# crm114 plugin - manageCategories command (interactive)
# One-time interactive setup: list, add, and remove classification categories in pluginStorage.
# Invoked by: doc.doc.sh run crm114 manageCategories -o <outputDir>
# Receives: $1=pluginStorage (passed as positional arg by cmd_run for interactive commands)
# Reads user input from /dev/tty to leave stdin free for the calling process.

set -euo pipefail

PLUGIN_STORAGE="${1:-}"

if [ -z "$PLUGIN_STORAGE" ]; then
  echo "Error: pluginStorage is required." >&2
  echo "Usage: doc.doc.sh run crm114 manageCategories -o <outputDir>" >&2
  exit 1
fi

# Security: reject path traversal in pluginStorage (REQ_SEC_005)
if [[ "$PLUGIN_STORAGE" == *".."* ]]; then
  echo "Error: Path traversal detected in pluginStorage" >&2
  exit 1
fi

# Ensure storage directory exists
mkdir -p "$PLUGIN_STORAGE"

# Helper: sanitize and validate category name
validate_category_name() {
  local name="$1"
  if ! [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    return 1
  fi
  return 0
}

# List existing categories
list_categories() {
  local found=()
  while IFS= read -r css_file; do
    found+=("$(basename "$css_file" .css)")
  done < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)
  printf '%s\n' "${found[@]+"${found[@]}"}"
}

# ---- Display existing categories ----
echo ""
echo "=== CRM114 Category Management ==="
echo "Storage: $PLUGIN_STORAGE"
echo ""

mapfile -t existing < <(list_categories)

if [ "${#existing[@]}" -eq 0 ]; then
  echo "No categories exist yet."
  echo ""
  echo "Enter one or more category names to create (one per line, empty line to finish):"
  while IFS= read -r cat_name < /dev/tty; do
    [ -z "$cat_name" ] && break
    if ! validate_category_name "$cat_name"; then
      echo "  Invalid name '$cat_name'. Use only alphanumeric characters, dash, underscore, or dot." >&2
      continue
    fi
    css_file="$PLUGIN_STORAGE/$cat_name.css"
    if [ ! -f "$css_file" ]; then
      # Initialize CSS model file via crm interpreter (csslearn does not exist in the package)
      _crm_init=$(mktemp /tmp/crm114_init_XXXXXX.crm)
      cat > "$_crm_init" << CRMEOF
window
input (:mytext:)
learn <osb> ($css_file) [:mytext:] //
CRMEOF
      printf ' ' | crm "$_crm_init" > /dev/null 2>&1 || touch "$css_file"
      rm -f "$_crm_init"
      echo "  Created category: $cat_name"
    else
      echo "  Category '$cat_name' already exists."
    fi
  done
else
  echo "Existing categories:"
  for cat in "${existing[@]}"; do
    echo "  - $cat"
  done
  echo ""

  # Add new categories
  echo "Add new categories (one per line, empty line to skip):"
  while IFS= read -r cat_name < /dev/tty; do
    [ -z "$cat_name" ] && break
    if ! validate_category_name "$cat_name"; then
      echo "  Invalid name '$cat_name'. Use only alphanumeric characters, dash, underscore, or dot." >&2
      continue
    fi
    css_file="$PLUGIN_STORAGE/$cat_name.css"
    if [ ! -f "$css_file" ]; then
      # Initialize CSS model file via crm interpreter (csslearn does not exist in the package)
      _crm_init=$(mktemp /tmp/crm114_init_XXXXXX.crm)
      cat > "$_crm_init" << CRMEOF
window
input (:mytext:)
learn <osb> ($css_file) [:mytext:] //
CRMEOF
      printf ' ' | crm "$_crm_init" > /dev/null 2>&1 || touch "$css_file"
      rm -f "$_crm_init"
      echo "  Created category: $cat_name"
    else
      echo "  Category '$cat_name' already exists."
    fi
  done

  # Remove categories
  echo ""
  mapfile -t current_cats < <(list_categories)
  if [ "${#current_cats[@]}" -gt 0 ]; then
    echo "Remove categories (enter name to delete, empty line to skip):"
    while IFS= read -r cat_name < /dev/tty; do
      [ -z "$cat_name" ] && break
      if ! validate_category_name "$cat_name"; then
        echo "  Invalid name '$cat_name'." >&2
        continue
      fi
      css_file="$PLUGIN_STORAGE/$cat_name.css"
      if [ ! -f "$css_file" ]; then
        echo "  Category '$cat_name' does not exist."
        continue
      fi
      printf "  Confirm delete '%s'? [y/N] " "$cat_name"
      read -r confirm < /dev/tty
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$css_file"
        echo "  Deleted category: $cat_name"
      else
        echo "  Skipped deletion of '$cat_name'."
      fi
    done
  fi
fi

echo ""
echo "=== Final categories ==="
mapfile -t final_cats < <(list_categories)
if [ "${#final_cats[@]}" -eq 0 ]; then
  echo "  (none)"
else
  for cat in "${final_cats[@]}"; do
    echo "  - $cat"
  done
fi
echo ""
echo "Done. Use 'doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train' to label documents."
