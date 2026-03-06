# TDD: Extract UI Module

- **ID:** TDD_FEATURE_0020
- **Priority:** HIGH
- **Type:** Task
- **Created at:** 2026-03-06
- **Created by:** developer.agent
- **Status:** DONE
- **Assigned to:** tester.agent

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Dependencies](#dependencies)
4. [Related Links](#related-links)

## Overview
Implement TDD tests for FEATURE_0020 (Extract UI Module). Tests must verify that `components/ui.sh` exists, is sourced by `doc.doc.sh`, and that all help/logging functions are delegated to it.

## Acceptance Criteria
- [x] Test script `tests/test_feature_0020.sh` exists
- [x] Tests verify `components/ui.sh` exists
- [x] Tests verify `doc.doc.sh` sources `ui.sh`
- [x] Tests verify `--help` output is byte-for-byte identical to baseline
- [x] Tests verify `doc.doc.sh` contains no inline help text or log-formatting code
- [x] Tests verify `ui.sh` declares a documented public interface
- [x] All tests initially fail (TDD red phase)

## Dependencies
- FEATURE_0020

## Related Links
- [FEATURE_0020 — Extract UI Module](FEATURE_0020_extract-ui-module.md)
