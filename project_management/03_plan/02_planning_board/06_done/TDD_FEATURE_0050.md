# TDD: FEATURE_0050 — Language Identification Plugin (langid)

- **ID:** TDD_FEATURE_0050
- **Type:** TDD Task
- **Created at:** 2026-03-28
- **Status:** DONE

## Overview

Test-driven development task for FEATURE_0050. Write tests in `tests/test_feature_0050.sh` covering:
- Plugin structure validation (directory, files, executables, descriptor)
- installed.sh behavior (exits 0 when langid is importable, reports false when not)
- languageCode is a two-letter ISO 639-1 string for English input
- languageCode is correct for non-English input (e.g. German)
- languageConfidence is a negative float (log-probability)
- Skip (exit 65) when no text fields are present
- Skip (exit 65) when all candidate text fields are empty
- documentText is preferred over ocrText when both are present
- Tests skip gracefully when langid is not installed
