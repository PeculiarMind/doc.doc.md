#!/bin/bash
# ui_progressbar.sh - Progress bar rendering for doc.doc.md
# Sourced by ui.sh; do not execute directly.
#
# Public Interface:
#   ui_progress_init <total>       - Initialise progress state with total document count
#   ui_progress_update <key> <val> - Update a progress field and re-render
#   ui_progress_done [count]       - Clear bar and print summary line

# --- Progress state struct (DEBTR_004) ---
# All progress display state variables are grouped here.
# Reset all state via ui_progress_init; no other function re-initialises from scratch.
_UI_PROGRESS_ENABLED=false
_UI_PROGRESS_TOTAL=0
_UI_PROGRESS_DONE=0
_UI_PROGRESS_PHASE=""
_UI_PROGRESS_STEP=""
_UI_PROGRESS_FOUND=0
_UI_PROGRESS_FILE=""
_UI_PROGRESS_DRAWN=false
_UI_PROGRESS_FRAME=0

ui_progress_init() {
  local total="${1:-0}"
  _UI_PROGRESS_ENABLED=true
  _UI_PROGRESS_TOTAL="$total"
  _UI_PROGRESS_DONE=0
  _UI_PROGRESS_PHASE=""
  _UI_PROGRESS_STEP=""
  _UI_PROGRESS_FOUND=0
  _UI_PROGRESS_FILE=""
  _UI_PROGRESS_DRAWN=false
  _UI_PROGRESS_FRAME=0

  trap '_ui_progress_clear; exit 130' INT
}

ui_progress_update() {
  local key="$1" value="$2"
  case "$key" in
    phase)   _UI_PROGRESS_PHASE="$value" ;;
    step)    _UI_PROGRESS_STEP="$value" ;;
    found)   _UI_PROGRESS_FOUND="$value" ;;
    file)    _UI_PROGRESS_FILE="$value" ;;
    done)    _UI_PROGRESS_DONE="$value" ;;
    total)   _UI_PROGRESS_TOTAL="$value" ;;
  esac
  _ui_progress_render
}

ui_progress_done() {
  local count="${1:-$_UI_PROGRESS_DONE}"
  _ui_progress_clear
  _UI_PROGRESS_ENABLED=false
  echo "Processed $count documents." >&2
  trap - INT
}

_ui_progress_render() {
  [ "$_UI_PROGRESS_ENABLED" = true ] || return 0

  local pct=0
  if [ "$_UI_PROGRESS_TOTAL" -gt 0 ]; then
    pct=$(( (_UI_PROGRESS_DONE * 100) / _UI_PROGRESS_TOTAL ))
  fi
  [ "$pct" -gt 100 ] && pct=100

  local bar_width=50
  local filled=$(( (pct * bar_width) / 100 ))
  local empty=$(( bar_width - filled ))

  # Advance animation frame on every render (cycles 0→1→0→…)
  _UI_PROGRESS_FRAME=$(( (_UI_PROGRESS_FRAME + 1) % 2 ))

  # Pick fill character for this frame — alternates to create a pulse effect
  local fill_char
  if   [ "$pct" -eq 100 ]; then fill_char="▓"
  elif [ "$_UI_PROGRESS_FRAME" -eq 0 ]; then fill_char="▒"
  else fill_char="▓"
  fi

  local bar=""
  if [ "$pct" -eq 0 ]; then
    bar=$(printf '%.0s░' $(seq 1 "$bar_width"))
  else
    [ "$filled" -gt 0 ] && bar=$(printf "%.0s${fill_char}" $(seq 1 "$filled"))
    [ "$empty" -gt 0 ] && bar+=$(printf '%.0s░' $(seq 1 "$empty"))
  fi

  if [ "$_UI_PROGRESS_DRAWN" = true ]; then
    printf '\033[u' >&2   # restore to saved position (robust against extra stderr lines)
  else
    printf '\033[s' >&2   # save cursor position before first render
  fi

  printf '\r\033[K%s\n' "Progress: ${bar} ${pct}%" >&2
  printf '\033[K%s\n' "Phase:    ${_UI_PROGRESS_PHASE}" >&2
  printf '\033[K%s\n' "Step:     ${_UI_PROGRESS_STEP}" >&2
  printf '\033[K%s\n' "Found:    ${_UI_PROGRESS_FOUND} documents" >&2
  printf '\033[K%s\n' "Process:  ${_UI_PROGRESS_FILE}" >&2
  
  _UI_PROGRESS_DRAWN=true
}

_ui_progress_clear() {
  [ "$_UI_PROGRESS_DRAWN" = true ] || return 0
  printf '\033[u' >&2   # restore to saved position (start of progress block)
  printf '\r\033[K\n%.0s' $(seq 1 6) >&2
  printf '\033[u' >&2   # leave cursor at start of cleared block for summary output
  _UI_PROGRESS_DRAWN=false
}
