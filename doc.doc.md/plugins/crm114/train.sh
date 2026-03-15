#!/bin/bash
# crm114 plugin - train command (interactive)
# Iterates documents in an input directory, displays file path and first 100
# words of extracted text, and prompts the user y/n per document/category pair
# to learn (y) or unlearn (n) the document into the category model.
#
# Uses `crm -e 'learn/unlearn ...'` instead of standalone css-learn/css-unlearn
# binaries, so only the `crm` binary (shipped by the Debian crm114 package) is
# required.
#
# Usage: train.sh <pluginStorage> <input_dir>
#
# Arguments:
#   pluginStorage  Path to the crm114 plugin storage directory (must exist)
#   input_dir      Path to the directory containing documents to label
#
# Exit codes: 0 success, 1 error

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_DOC_SH="$PLUGIN_DIR/../../../doc.doc.sh"

# ---- Argument validation ----

if [ $# -lt 2 ]; then
  echo "Usage: train.sh <pluginStorage> <input_dir>" >&2
  echo "  pluginStorage  Path to crm114 plugin storage directory" >&2
  echo "  input_dir      Path to directory of documents to label" >&2
  exit 1
fi

RAW_STORAGE="$1"
RAW_INPUT_DIR="$2"

# Validate pluginStorage path (REQ_SEC_005)
CANONICAL_STORAGE=$(readlink -f "$RAW_STORAGE" 2>/dev/null) || CANONICAL_STORAGE=""
if [ -z "$CANONICAL_STORAGE" ] || [ ! -d "$CANONICAL_STORAGE" ]; then
  echo "Error: pluginStorage directory does not exist: $RAW_STORAGE" >&2
  exit 1
fi

# Validate input directory
CANONICAL_INPUT=$(readlink -f "$RAW_INPUT_DIR" 2>/dev/null) || CANONICAL_INPUT=""
if [ -z "$CANONICAL_INPUT" ] || [ ! -d "$CANONICAL_INPUT" ]; then
  echo "Error: Input directory does not exist: $RAW_INPUT_DIR" >&2
  exit 1
fi

# ---- Helper: sanitize_category ----
# Validates a category name (alphanumeric, dash, underscore, dot only)
# Returns 0 if valid, 1 if invalid
sanitize_category() {
  local cat="$1"
  if echo "$cat" | grep -qE '^[a-zA-Z0-9._-]+$'; then
    return 0
  fi
  return 1
}

# ---- Step 1: Category management ----

echo ""
echo "=== CRM114 Training Session ==="
echo "  pluginStorage: $CANONICAL_STORAGE"
echo "  input dir:     $CANONICAL_INPUT"
echo ""

# Discover existing categories (.css files)
shopt -s nullglob
existing_css=("$CANONICAL_STORAGE"/*.css)
shopt -u nullglob

declare -a categories=()
for css_file in "${existing_css[@]}"; do
  categories+=("$(basename "$css_file" .css)")
done

if [ ${#categories[@]} -eq 0 ]; then
  echo "No existing categories found in pluginStorage."
  echo "Enter one or more category names (alphanumeric, dash, underscore, dot)."
  echo "Enter an empty line when done:"
  while true; do
    printf "  Category name: "
    read -r new_cat </dev/tty
    if [ -z "$new_cat" ]; then
      break
    fi
    if ! sanitize_category "$new_cat"; then
      echo "  Invalid name — only alphanumeric, dash, underscore, and dot are allowed." >&2
      continue
    fi
    categories+=("$new_cat")
    echo "  Added: $new_cat"
  done
  if [ ${#categories[@]} -eq 0 ]; then
    echo "Error: At least one category is required." >&2
    exit 1
  fi
else
  echo "Existing categories:"
  for cat in "${categories[@]}"; do
    echo "  - $cat"
  done
  echo ""
  echo "Add new categories? (Enter names one per line, empty line to continue):"
  while true; do
    printf "  New category (or press Enter to skip): "
    read -r new_cat </dev/tty
    if [ -z "$new_cat" ]; then
      break
    fi
    if ! sanitize_category "$new_cat"; then
      echo "  Invalid name — only alphanumeric, dash, underscore, and dot are allowed." >&2
      continue
    fi
    categories+=("$new_cat")
    echo "  Added: $new_cat"
  done
fi

echo ""
echo "Categories for this session: ${categories[*]}"
echo ""

# Check CRM114 availability
if ! command -v crm >/dev/null 2>&1; then
  echo "Error: crm is not available — install crm114 first." >&2
  exit 1
fi

# Check doc.doc.sh availability
if [ ! -x "$DOC_DOC_SH" ]; then
  echo "Error: doc.doc.sh not found at $DOC_DOC_SH" >&2
  exit 1
fi

# ---- Step 2: Document labeling loop ----

echo "=== Document Labeling Loop ==="
echo "(y = learn this document, n = unlearn, s = skip document, q = quit)"
echo ""

doc_count=0
trained_count=0

# Discover documents in input directory
while IFS= read -r -d '' file_path; do
  [ -f "$file_path" ] || continue
  doc_count=$((doc_count + 1))

  echo "--- Document $doc_count ---"
  echo "  File: $file_path"

  # Extract text via doc.doc.sh process (full pipeline) using echo mode
  extracted_text=$(bash "$DOC_DOC_SH" process -d "$(dirname "$file_path")" \
    -i "$(basename "$file_path")" --echo --no-progress 2>/dev/null \
    | grep -v "^===" | grep -v "^$" | head -c 4096) || extracted_text=""

  # If extraction failed, fall back to raw text
  if [ -z "$extracted_text" ]; then
    extracted_text=$(cat "$file_path" 2>/dev/null | head -c 4096) || extracted_text=""
  fi

  # Display first 100 words
  first_100_words=$(echo "$extracted_text" | tr '\n' ' ' | tr -s ' ' | \
    cut -d ' ' -f 1-100 | fold -s -w 80)
  echo "  First 100 words:"
  echo "$first_100_words" | sed 's/^/    /'
  echo ""

  # Per-category labeling
  # Read raw file content once for all categories in this document
  raw_text=$(head -c 1048576 "$file_path" 2>/dev/null) || raw_text=""

  for cat in "${categories[@]}"; do
    CSS_FILE="$CANONICAL_STORAGE/$cat.css"

    while true; do
      printf "  [%s] y=learn  n=unlearn  s=skip  q=quit: " "$cat"
      read -r choice </dev/tty
      case "$choice" in
        y|Y)
          # Use raw file content for training (not rendered markdown)
          if [ -n "$raw_text" ]; then
            if echo "$raw_text" | crm '-{ learn <osb unique microgroom> ( '"$CSS_FILE"' ) }' >/dev/null 2>&1; then
              echo "    ✓ Learned into '$cat'"
              trained_count=$((trained_count + 1))
            else
              echo "    ✗ crm learn failed for '$cat'" >&2
            fi
          else
            echo "    ! No text content, skipping."
          fi
          break
          ;;
        n|N)
          # crm unlearn: remove from model
          if [ -f "$CSS_FILE" ] && [ -n "$raw_text" ]; then
            if echo "$raw_text" | crm '-{ unlearn <osb unique microgroom> ( '"$CSS_FILE"' ) }' >/dev/null 2>&1; then
              echo "    ✓ Unlearned from '$cat'"
            else
              echo "    ✗ crm unlearn failed for '$cat'" >&2
            fi
          else
            echo "    ! Model does not exist or no text, skipping unlearn."
          fi
          break
          ;;
        s|S)
          echo "    → Skipped."
          break
          ;;
        q|Q)
          echo ""
          echo "=== Training session ended early. ==="
          echo "  Documents processed: $doc_count"
          echo "  Training operations: $trained_count"
          exit 0
          ;;
        *)
          echo "  Please enter y, n, s, or q."
          ;;
      esac
    done
  done
  echo ""
done < <(find "$CANONICAL_INPUT" -type f -print0 2>/dev/null)

echo "=== Training session complete. ==="
echo "  Documents processed: $doc_count"
echo "  Training operations: $trained_count"
