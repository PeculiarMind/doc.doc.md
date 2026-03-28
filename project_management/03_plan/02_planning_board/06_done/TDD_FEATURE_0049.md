# TDD: FEATURE_0049 — Word Coverage Plugin

- **ID:** TDD_FEATURE_0049
- **Type:** TDD Task
- **Created at:** 2026-03-28
- **Status:** DONE

## Overview

Test-driven development task for FEATURE_0049. Write tests in `tests/test_feature_0049.sh` covering:
- Plugin structure validation (directory, files, executables, descriptor)
- installed.sh always exits 0 (no external dependencies)
- summaryCoveragePercent correctly calculated when wordCount > maxWords
- summaryCoveragePercent is 100.0 when wordCount <= maxWords
- Skip (exit 65) when wordCount is absent
- Skip (exit 65) when wordCount is zero
- Custom maxWords is respected
- Invalid/missing maxWords falls back to default (100)
