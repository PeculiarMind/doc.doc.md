# Feature: Implement Semantic Timestamp Versioning (ADR-0012)

## Status
Backlog

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

## Related
- [ADR-0012: Semantic Timestamp Versioning Pattern](../../01_vision/03_architecture/09_architecture_decisions/ADR_0012_semantic_timestamp_versioning_pattern.md)
- README.md (badges, documentation)
- scripts/doc.doc.sh (CLI output)
- Agent system (developer, readme-maintainer)
- Changelog, release notes

---

**Created by:** readme-maintainer agent
**Date:** 2026-02-13
