# Word Coverage Plugin

- **ID:** FEATURE_0049
- **Priority:** LOW
- **Type:** Feature
- **Created at:** 2026-03-15
- **Created by:** Product Owner
- **Status:** FUNNEL

## TOC
1. [Overview](#overview)
2. [Acceptance Criteria](#acceptance-criteria)
3. [Scope](#scope)
4. [Technical Requirements](#technical-requirements)
5. [Dependencies](#dependencies)
6. [Related Links](#related-links)

## Overview

Implement a `wordcoverage` plugin that calculates what percentage of a document's full text is represented by a given maximum word count. This answers the question: *"If I read only the first N words, what fraction of the total document have I seen?"*

The plugin operates as a standard stateless pipeline plugin: it reads `wordCount` (the total word count already computed by the `wc` plugin) and a configurable `maxWords` threshold from the accumulated pipeline JSON context, and returns the coverage ratio — without any text processing or file I/O of its own.

**Calculation rules:**
- If `wordCount > maxWords`: `coveragePercent = (maxWords / wordCount) * 100` (rounded to two decimal places).
- If `wordCount <= maxWords`: `coveragePercent = 100.0` (the max covers the entire text).

**Business Value:**
- Provides a quantitative measure of how representative a fixed-length excerpt (e.g. first 100 words displayed by the `crm114 train` command) is of the full document
- Enables downstream filtering or flagging of very long documents where a short preview may be insufficient for confident labeling
- Purely stateless — no storage, no side effects; slots cleanly into the existing pipeline

**What this delivers:**
- `wordcoverage` plugin under `doc.doc.md/plugins/wordcoverage/` following the standard plugin structure (`descriptor.json`, `main.sh`, `install.sh`, `installed.sh`)
- `main.sh` receives accumulated pipeline JSON on stdin, reads `wordCount` (required, integer) and the optional `maxWords` threshold, applies the coverage formula, and returns `summaryMaxWords` and `summaryCoveragePercent` in the JSON output
- If `wordCount` is absent or zero in the pipeline context, the plugin exits with code 65 (skip — ADR-004)
- No text field access, no `wc` invocation, no filesystem access — purely arithmetic on pipeline values
- `installed.sh` confirms the plugin has no external dependencies (exits 0)

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin directory `doc.doc.md/plugins/wordcoverage/` contains `descriptor.json`, `main.sh`, `install.sh`, and `installed.sh`
- [ ] All scripts are executable (`chmod +x`)
- [ ] `descriptor.json` declares `name`, `version`, `description`, `active` flag, `dependencies`, and a `process` command with `input`/`output` JSON schemas
- [ ] `descriptor.json` passes the existing plugin descriptor validation (REQ_SEC_003)

### process Command (`main.sh`)
- [ ] Reads accumulated pipeline JSON from stdin
- [ ] Extracts `wordCount` (required, positive integer) from the JSON input
- [ ] If `wordCount` is absent, zero, or not a positive integer, exits with code 65 (skip — ADR-004)
- [ ] Accepts an optional `maxWords` field (positive integer); defaults to `100` if absent, zero, or invalid
- [ ] Applies the coverage calculation:
  - If `wordCount > maxWords`: `coveragePercent = round((maxWords / wordCount) * 100, 2)`
  - If `wordCount <= maxWords`: `coveragePercent = 100.0`
- [ ] Returns valid JSON to stdout:
```json
{
  "summaryMaxWords": <integer>,
  "summaryCoveragePercent": <float, 0.0–100.0>
}
```
- [ ] Logs errors to stderr; stdout contains only valid JSON or nothing
- [ ] Never reads from or writes to the filesystem

### install Command (`install.sh`)
- [ ] Prints a message that `wordcoverage` requires no external tools
- [ ] Exits 0

### installed Command (`installed.sh`)
- [ ] Always exits 0 (no external dependencies)

### Dependency Declaration
- [ ] `descriptor.json` declares `wc` (FEATURE_0048) as a required upstream dependency (provides `wcWordCount`)

### Security
- [ ] No text content or file paths are processed; plugin only performs arithmetic on integer inputs (REQ_SEC_005)
- [ ] `wordCount` and `maxWords` are validated as positive integers before use; invalid values trigger skip or default (no injection vector)- [ ] All JSON input is validated before processing (REQ_SEC_009)

### Tests
- [ ] `tests/test_feature_0049.sh` covers:
  - `summaryCoveragePercent` is correctly calculated when `wordCount > maxWords`
  - `summaryCoveragePercent` is `100.0` when `wordCount <= maxWords`
  - Skip (exit 65) when `wordCount` is absent from the pipeline JSON
  - Skip (exit 65) when `wordCount` is zero
  - Custom `maxWords` is respected
  - Invalid/missing `maxWords` falls back to default (100)
  - `installed.sh` exits 0
- [ ] All existing tests continue to pass

## Scope

### In Scope
- `doc.doc.md/plugins/wordcoverage/descriptor.json`
- `doc.doc.md/plugins/wordcoverage/main.sh`
- `doc.doc.md/plugins/wordcoverage/install.sh`
- `doc.doc.md/plugins/wordcoverage/installed.sh`
- Default template update: add `{{summaryMaxWords}}`, `{{summaryCoveragePercent}}` placeholders to `doc.doc.md/templates/default.md`
- TDD test suite `tests/test_feature_0049.sh`

### Out of Scope
- Word counting (delegated to the `wc` plugin — FEATURE_0048)
- Text field access of any kind
- Producing a truncated excerpt of the text (the plugin calculates coverage only)
- Sentence-level or token-level coverage (word-based only)

## Technical Requirements

- Coverage calculation: `awk "BEGIN { printf \"%.2f\", ($maxWords / $wordCount) * 100 }"` or equivalent
- `wordCount` and `maxWords` validated as positive integers before use
- JSON output assembled via `jq`
- No text processing; no calls to `wc` or any text tool
- Exit code 65 (ADR-004) for all intentional skips

## Dependencies

- **FEATURE_0048** (`wc` plugin): provides `wordCount` in the pipeline context (required upstream)
- **ADR-004** (exit code 65 skip contract)

## Related Links
- Architecture Vision: `project_documentation/01_architecture/`
- Requirements: `project_management/02_project_vision/02_requirements/`
