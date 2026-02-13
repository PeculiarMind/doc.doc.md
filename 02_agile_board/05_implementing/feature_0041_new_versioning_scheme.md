# Feature: Implement Semantic Timestamp Versioning (ADR-0012)

## Status
Implementing

**Started**: 2026-02-13T20:58:30Z  
**Developer**: Developer Agent  
**Branch**: copilot/work-on-backlog-items

## Motivation
The project must adopt the versioning scheme defined in [ADR-0012: Semantic Timestamp Versioning Pattern](../../01_vision/03_architecture/09_architecture_decisions/ADR_0012_semantic_timestamp_versioning_pattern.md) to:
- Clearly communicate release date and context
- Support multiple releases per day
- Provide memorable, human-friendly release identifiers
- Enable fully automated, agent-driven release management

## Requirements (per ADR-0012)
- Implement version string generation as:
	`<YEAR>_<CREATIVE_NAME>_<MMDD>.<SECONDS_OF_DAY>` (e.g., `2026_Phoenix_0213.54321`)
	- YEAR: Four-digit year (UTC)
	- CREATIVE_NAME: Curated codename for the release period (see ADR-0012 for naming guidance)
	- MMDD: Month and day (UTC)
	- SECONDS_OF_DAY: Seconds since midnight UTC
- Automate version string generation in CI/CD and agent workflows
- Update all version references in:
	- README.md (badges, documentation)
	- scripts/doc.doc.sh (CLI output, help text)
	- Any other visible locations (e.g., agent reports, changelogs)
- The creative name part of the version string must be maintained by the author in the file `scripts/components/version_name.txt`. This file is the single source of truth for the current release codename and is read by the versioning logic.
- All other parts of the version string (YEAR, MMDD, SECONDS_OF_DAY) are determined automatically at the time of each change, using the current system time, before a pull request is created.
- All relevant agent personas (developer, readme-maintainer, etc.) must follow these instructions for version string management and ensure compliance in their workflows.
- Maintain and document the creative name registry in project documentation
- Document the new versioning scheme, rationale, and migration steps in the README
- Update changelog and release notes to use the new versioning format
- Ensure git tags and packaging scripts use the new version string
- Remove SemVer references from user-facing documentation (except for migration notes)
- Provide FAQ and examples for users (see ADR-0012 Communication section)

## Acceptance Criteria
- [ ] Version string is generated and used as specified in ADR-0012
- [ ] All project references and tooling are updated to the new scheme
- [ ] Creative name registry is maintained and documented
- [ ] Migration from SemVer is documented in README and changelog
- [ ] Automated versioning is integrated into agent/CI workflows
- [ ] User documentation and FAQ are updated

## Test Coverage

**Test Suite**: `tests/unit/test_semantic_timestamp_versioning.sh`  
**Total Tests**: 36  
**Status**: ✅ All passing

### Test Groups

#### 1. Version Format Validation (6 tests)
- ✅ Version format matches ADR-0012 pattern: `<YEAR>_<NAME>_<MMDD>.<SECONDS>`
- ✅ Invalid format patterns are rejected (wrong separators, missing components, etc.)
- ✅ Extract year component from version string
- ✅ Extract creative name component from version string
- ✅ Extract MMDD component from version string  
- ✅ Extract seconds of day component from version string

#### 2. Creative Name Management (6 tests)
- ✅ Creative name file exists at `scripts/components/version_name.txt`
- ✅ Creative name file is readable
- ✅ Creative name is not empty
- ✅ Creative name starts with uppercase letter
- ✅ Creative name contains only alphabetic characters
- ✅ Missing creative name file is detected gracefully

#### 3. Timestamp Calculation (8 tests)
- ✅ Year component is 4 digits (UTC)
- ✅ MMDD component format is valid (4 digits)
- ✅ Month component is valid (01-12)
- ✅ Day component is valid (01-31)
- ✅ Seconds of day is valid range (0-86399)
- ✅ Midnight (00:00:00) = 0 seconds
- ✅ Noon (12:00:00) = 43200 seconds
- ✅ End of day (23:59:59) = 86399 seconds

#### 4. Version Comparison and Sorting (5 tests)
- ✅ Versions sort chronologically by year
- ✅ Versions with same year sort by MMDD
- ✅ Versions with same date sort by seconds
- ✅ Multiple versions sort correctly in chronological order
- ✅ Creative name variations don't affect chronological sorting

#### 5. Error Handling (7 tests)
- ✅ Detect invalid month 00
- ✅ Detect invalid month 13+
- ✅ Detect invalid day 00
- ✅ Detect invalid day 32+
- ✅ Detect negative seconds of day
- ✅ Detect seconds of day overflow (>= 86400)
- ✅ Detect empty creative name file

#### 6. Integration Scenarios (4 tests)
- ✅ Generate complete version string from components
- ✅ Parse and reconstruct version string identically
- ✅ Generate version with current system timestamp
- ✅ Sequential versions differ (monotonic increase)

### Test Approach

Tests follow **Test-Driven Development (TDD)** principles:
- Define expected behavior before implementation
- Cover happy path, edge cases, and error conditions
- Validate format, components, calculations, and integration
- Ensure version strings are comparable and sortable chronologically

### Next Steps for Developer Agent

The test suite defines the expected behavior. Implementation should:
1. Create version generation logic in `scripts/components/` or similar
2. Read creative name from `scripts/components/version_name.txt`
3. Calculate timestamp components (YEAR, MMDD, SECONDS_OF_DAY) from UTC time
4. Integrate version generation into main script and CI/CD workflows
5. Update all version references per requirements
6. Run test suite to verify implementation: `./tests/unit/test_semantic_timestamp_versioning.sh`

## Related
- [ADR-0012: Semantic Timestamp Versioning Pattern](../../01_vision/03_architecture/09_architecture_decisions/ADR_0012_semantic_timestamp_versioning_pattern.md)
- README.md (badges, documentation)
- scripts/doc.doc.sh (CLI output)
- Agent system (developer, readme-maintainer)
- Changelog, release notes

---

**Created by:** readme-maintainer agent
**Date:** 2026-02-13
