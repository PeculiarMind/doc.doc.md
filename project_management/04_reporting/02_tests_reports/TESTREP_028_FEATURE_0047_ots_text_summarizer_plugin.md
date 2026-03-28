# Test Report: FEATURE_0047 — OTS Text Summarizer Plugin

- **ID:** TESTREP_028
- **Work Item:** FEATURE_0047
- **Date:** 2026-03-28
- **Status:** PASS

## Summary

All 45 tests passed for the OTS text summarizer plugin.

## Test Coverage

| Group | Description | Tests | Result |
|-------|-------------|-------|--------|
| 1 | Plugin structure validation | 14 | ✅ PASS |
| 2 | installed.sh functionality | 3 | ✅ PASS |
| 3 | install.sh functionality | 1 | ✅ PASS |
| 4 | Text processing via textContent | 4 | ✅ PASS |
| 5 | ocrText fallback behavior | 2 | ✅ PASS |
| 6 | documentText fallback behavior | 2 | ✅ PASS |
| 7 | Exit code 65 when no text available | 2 | ✅ PASS |
| 8 | summaryRatio validation and defaults | 6 | ✅ PASS |
| 9 | languageCode dictionary selection | 6 | ✅ PASS |
| 10 | Valid JSON output and no disk writes | 5 | ✅ PASS |
| **Total** | | **45** | **✅ ALL PASS** |

## Test Details

### Group 1: Plugin Structure
- Plugin directory exists at `doc.doc.md/plugins/ots/`
- Required files present: `descriptor.json`, `main.sh`, `install.sh`, `installed.sh`
- All shell scripts are executable
- `descriptor.json` is valid JSON with required fields (name, version, description, active)
- Plugin name is correctly set to `ots`

### Group 2: installed.sh
- Exits 0 (reporting status, not failing)
- Returns valid JSON output
- Correctly reports installed status based on `ots` binary availability

### Group 3: install.sh
- Exits 0 when `ots` is already available

### Group 4: textContent Processing
- Summary produced from textContent field (highest priority)
- Output contains `summaryText`, `summaryRatio`, and `summaryLanguage` fields
- Default summaryRatio is 20

### Group 5: ocrText Fallback
- Falls back to ocrText when textContent is empty
- Summary is produced correctly

### Group 6: documentText Fallback
- Falls back to documentText when textContent and ocrText are empty
- Summary is produced correctly

### Group 7: Skip Behavior
- Exits 65 when no text fields are present in pipeline JSON
- Exits 65 when all text fields are empty strings

### Group 8: summaryRatio Handling
- Custom summaryRatio (50) is passed through correctly
- Invalid summaryRatio ("invalid") falls back to default (20)
- summaryRatio 0 falls back to default (20)
- summaryRatio 101 falls back to default (20)

### Group 9: languageCode Dictionary Selection
- Absent languageCode results in summaryLanguage: null
- Unknown dictionary code ("zh") results in summaryLanguage: null
- Malicious languageCode ("../etc/passwd") is rejected, summaryLanguage: null
- Valid languageCode ("en") with matching dictionary sets summaryLanguage: "en"

### Group 10: Output Validation
- stdout is valid JSON
- All three output fields (summaryText, summaryRatio, summaryLanguage) present
- No files written to disk during processing

## Conclusion

The OTS text summarizer plugin implementation passes all acceptance criteria. The plugin correctly handles text prioritization, summary ratio validation, language dictionary selection, security constraints, and ADR-004 exit code compliance.
