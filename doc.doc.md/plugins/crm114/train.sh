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
if [ ! -d "$PLUGIN_STORAGE" ]; then
  echo "No categories exist. Run 'doc.doc.sh run crm114 manageCategories -o <outputDir>' first." >&2
  exit 65
fi

# Find trained categories
mapfile -t CSS_FILES < <(find "$PLUGIN_STORAGE" -maxdepth 1 -name "*.css" 2>/dev/null | sort)

if [ "${#CSS_FILES[@]}" -eq 0 ]; then
  echo "No categories exist. Run 'doc.doc.sh run crm114 manageCategories -o <outputDir>' first." >&2
  exit 65
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
  read -r choice < /dev/tty || choice="s"
  choice="${choice:-s}"

  case "$choice" in
    t|T|train)
      if [ -n "$TEXT" ]; then
        if command -v csslearn >/dev/null 2>&1; then
          printf '%s\n' "$TEXT" | csslearn "$css_file" 2>/dev/null && \
            echo "    → Trained '$cat_name'" || \
            echo "    → csslearn failed for '$cat_name'" >&2
        else
          echo "    → csslearn not available; cannot train" >&2
        fi
      else
        echo "    → No text available for training" >&2
      fi
      ;;
    u|U|untrain)
      if [ -n "$TEXT" ]; then
        if command -v cssunlearn >/dev/null 2>&1; then
          if [ -f "$css_file" ]; then
            printf '%s\n' "$TEXT" | cssunlearn "$css_file" 2>/dev/null && \
              echo "    → Untrained '$cat_name'" || \
              echo "    → cssunlearn failed for '$cat_name'" >&2
          else
            echo "    → No model file for '$cat_name' to untrain" >&2
          fi
        else
          echo "    → cssunlearn not available; cannot untrain" >&2
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
