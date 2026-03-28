# TDD: FEATURE_0047 — OTS Text Summarizer Plugin

- **ID:** TDD_FEATURE_0047
- **Type:** TDD Task
- **Created at:** 2026-03-28
- **Status:** DONE

## Overview

Test-driven development task for FEATURE_0047. Write tests in `tests/test_feature_0047.sh` covering:
- Plugin structure validation (directory, files, executables, descriptor)
- installed.sh behavior (exits 0 when ots is on PATH, non-zero otherwise)
- install.sh exits 0
- Summary produced from textContent, ocrText, and documentText fields (priority order)
- Skip (exit 65) when no text field is present
- Skip (exit 65) when ots produces empty output
- Custom summaryRatio is passed through correctly
- Invalid summaryRatio falls back to default (20)
- languageCode dictionary selection (when dictionary exists and doesn't exist)
- Invalid/malicious languageCode values rejected
- Tests skip gracefully when ots is not installed
