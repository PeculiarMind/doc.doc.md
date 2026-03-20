#!/bin/bash
# crm114 plugin - train command (interactive, per-document)
# Per-document interactive labeling: displays file path and first 100 words,
# then prompts t/u/s (train/untrain/skip) per category.
# Invoked by: doc.doc.sh loop -d <docsDir> -o <outputDir> --plugin crm114 train
# Receives: JSON on stdin (from loop) with filePath, pluginStorage, textContent/ocrText
# Reads user input from /dev/tty to leave stdin free for JSON from the loop.
# Exit codes: 0 success, 65 skip (ADR-004: no categories), 1 failure

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../components/plugin_input.sh"

plugin_read_input

FILE_PATH=$(plugin_get_field "filePath")
PLUGIN_STORAGE=$(plugin_get_field "pluginStorage")
TEXT_CONTENT=$(plugin_get_field "textContent")
OCR_TEXT=$(plugin_get_field "ocrText")

# Validate required fields
if [ -z "$FILE_PATH" ]; then
  echo "Error: Missing 'filePath' in JSON input" >&2
  exit 1
fi

if [ -z "$PLUGIN_STORAGE" ]; then
  echo "Error: Missing 'pluginStorage' in JSON input" >&2
  exit 1
fi

# Security: reject path traversal in pluginStorage (REQ_SEC_005)
if [[ "$PLUGIN_STORAGE" == *".."* ]]; then
  echo "Error: Path traversal detected in pluginStorage" >&2
  exit 1
fi

# Ensure storage exists
mkdir -p "$PLUGIN_STORAGE"

# Helper: sanitize and validate category name (same rules as manageCategories)
_validate_category_name() {
  local name="$1"
  if ! [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    return 1
  fi
  return 0
}

# Determine tty source (allow override for testing)
_TTY_SOURCE="${CRM114_TTY_OVERRIDE:-/dev/tty}"

# Find trained categories
mapfile -t CSS_FILES < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)

# If no categories exist, prompt for inline creation before labeling
if [ "${#CSS_FILES[@]}" -eq 0 ]; then
  echo "" >&2
  echo "No categories exist yet." >&2
  echo "Enter one or more category names to create (one per line, empty line to finish):" >&2

  # Check TTY source is available before attempting exec
  if [ ! -r "$_TTY_SOURCE" ]; then
    echo "No terminal available for interactive category creation. Exiting." >&2
    exit 65
  fi

  exec 3< "$_TTY_SOURCE"

  while IFS= read -r cat_name <&3; do
    [ -z "$cat_name" ] && break
    if ! _validate_category_name "$cat_name"; then
      echo "  Invalid name '$cat_name'. Use only alphanumeric characters, dash, underscore, or dot." >&2
      continue
    fi
    css_file="$PLUGIN_STORAGE/$cat_name.css"
    if [ ! -f "$css_file" ]; then
      _crm_init=$(mktemp /tmp/crm114_init_XXXXXX.crm)
      cat > "$_crm_init" << CRMEOF
window
input (:mytext:)
learn <osb> ($css_file) [:mytext:] //
CRMEOF
      printf ' ' | crm "$_crm_init" > /dev/null 2>&1 || touch "$css_file"
      rm -f "$_crm_init"
      echo "  Created category: $cat_name" >&2
    else
      echo "  Category '$cat_name' already exists." >&2
    fi
  done
  exec 3<&-

  # Re-scan for categories after inline creation
  mapfile -t CSS_FILES < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)

  if [ "${#CSS_FILES[@]}" -eq 0 ]; then
    echo "No categories were created. Exiting." >&2
    exit 65
  fi
fi

# Build category names list
categories=()
for css_file in "${CSS_FILES[@]}"; do
  categories+=("$(basename "$css_file" .css)")
done

# Resolve text: prefer textContent, fall back to ocrText
TEXT="${TEXT_CONTENT:-}"
if [ -z "$TEXT" ]; then
  TEXT="${OCR_TEXT:-}"
fi

# Display document header
echo ""
echo "── Document ──────────────────────────────────────"
echo "  File: $FILE_PATH"

if [ -n "$TEXT" ]; then
  # Show first 100 words
  preview=$(printf '%s' "$TEXT" | tr -s '[:space:]' ' ' | cut -d' ' -f1-100)
  echo ""
  echo "  Preview (first 100 words):"
  echo "  $preview"
fi
echo "──────────────────────────────────────────────────"

# Per-category prompting
for cat_name in "${categories[@]}"; do
  css_file="$PLUGIN_STORAGE/$cat_name.css"

  printf "  Category [%s]: (t)rain / (u)ntrain / (s)kip [s]: " "$cat_name"
  choice=""
  read -r choice < "$_TTY_SOURCE" || choice="s"
  choice="${choice:-s}"

  case "$choice" in
    t|T|train)
      if [ -n "$TEXT" ]; then
        _crm_train=$(mktemp /tmp/crm114_train_XXXXXX.crm)
        cat > "$_crm_train" << CRMEOF
window
input (:mytext:)
learn <osb microgroom> ($css_file) [:mytext:] //
CRMEOF
        if printf '%s\n' "$TEXT" | crm "$_crm_train" > /dev/null 2>&1; then
          echo "    → Trained '$cat_name'"
        else
          echo "    → crm114 learn failed for '$cat_name'" >&2
        fi
        rm -f "$_crm_train"
      else
        echo "    → No text available for training" >&2
      fi
      ;;
    u|U|untrain)
      if [ -n "$TEXT" ]; then
        if [ -f "$css_file" ]; then
          _crm_untrain=$(mktemp /tmp/crm114_untrain_XXXXXX.crm)
          cat > "$_crm_untrain" << CRMEOF
window
input (:mytext:)
learn <osb microgroom refute> ($css_file) [:mytext:] //
CRMEOF
          if printf '%s\n' "$TEXT" | crm "$_crm_untrain" > /dev/null 2>&1; then
            echo "    → Untrained '$cat_name'"
          else
            echo "    → crm114 learn refute failed for '$cat_name'" >&2
          fi
          rm -f "$_crm_untrain"
        else
          echo "    → No model file for '$cat_name' to untrain" >&2
        fi
      else
        echo "    → No text available for untraining" >&2
      fi
      ;;
    s|S|skip|"")
      echo "    → Skipped '$cat_name'"
      ;;
    *)
      echo "    → Unknown choice '$choice'; skipping '$cat_name'"
      ;;
  esac
done

echo ""
