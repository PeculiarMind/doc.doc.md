# ADR-0012: Semantic Timestamp Versioning Pattern

**ID**: ADR-0012  
**Status**: Accepted  
**Created**: 2026-02-13  
**Last Updated**: 2026-02-13

## Context

The project requires a versioning scheme that balances human-readability with automated release management. The version identifier must:
- Clearly identify when a release was created
- Support multiple releases per day in rapid development cycles
- Be memorable and easy to communicate to users
- Sort chronologically by default
- Be deterministic and reproducible from release metadata

Traditional semantic versioning (MAJOR.MINOR.PATCH) doesn't capture temporal information, while pure timestamp versioning lacks human-friendly naming and context.

## Decision

Adopt a hybrid **Semantic Timestamp Versioning Pattern**:

```
<FOUR_DIGIT_YEAR>_<CREATIVE_NAME>_<MMDD>.<SECONDS_OF_DAY>
```

**Components**:
- **FOUR_DIGIT_YEAR**: Four-digit year (e.g., `2026`)
- **CREATIVE_NAME**: Descriptive release codename (e.g., `Phoenix`, `Aurora`, `Velocity`)
- **MMDD**: Zero-padded month and day (e.g., `0213` for February 13th)
- **SECONDS_OF_DAY**: Seconds elapsed since midnight UTC (0-86399)

**Example**: `2026_Phoenix_0213.54321`

## Rationale

**Strengths**:
- **Chronological Sorting**: Year-first format ensures natural chronological ordering
- **Human Readability**: Creative name makes releases memorable and marketable
- **Temporal Precision**: MMDD + seconds enables multiple daily releases with microsecond-level uniqueness
- **Deterministic**: Timestamp-based versioning is reproducible from CI/CD metadata
- **Communication Friendly**: Users can reference "the Phoenix release" or "2026 Phoenix"
- **Automated Release Support**: Seconds-of-day counter eliminates manual version bumping
- **Git Tag Compatible**: Alphanumeric format works seamlessly with git tagging

**Weaknesses**:
- **No Backward Compatibility Signal**: Doesn't indicate breaking changes like SemVer
- **Creative Name Management**: Requires curating release codenames
- **Length**: Longer than traditional version strings (may impact display in constrained UIs)
- **Timezone Dependency**: Requires consistent timezone (UTC) for reproducibility

## Alternatives Considered

### Semantic Versioning (SemVer)
- ✅ Industry standard, clear backward compatibility signals
- ✅ Well-supported by package managers and tooling
- ❌ Manual version bumping prone to human error
- ❌ Doesn't capture temporal information
- ❌ Arbitrary numbering lacks context
- **Decision**: Good for libraries, but lacks temporal context needed for rapid release cycles

### Calendar Versioning (CalVer)
- ✅ Temporal information (e.g., `2026.02.1`)
- ✅ Automated date-based versioning
- ❌ No human-friendly naming
- ❌ Multiple releases per day require counter management
- **Decision**: Close match, but lacks memorable naming component

### Pure Timestamp
- ✅ Fully automated, no conflicts
- ✅ Precise temporal information
- ❌ Completely unmemorable (e.g., `1707846321`)
- ❌ No context or human-friendly naming
- **Decision**: Too machine-oriented for user-facing releases

### Git Commit Hash
- ✅ Deterministic and unique
- ❌ No temporal or contextual information
- ❌ Difficult to remember and communicate
- **Decision**: Better suited for CI artifacts than releases

### Hybrid CalVer + SemVer
- ✅ Combines temporal and compatibility information (e.g., `2026.02.1-beta.3`)
- ❌ Still lacks creative naming
- ❌ Complexity in managing both schemes
- **Decision**: Overly complex for single-script tool

## Consequences

### Positive
- **Release Communication**: "Download the Phoenix release" is clearer than "Download version 1.4.2"
- **Automated CI/CD**: Version string generated from build timestamp eliminates manual intervention
- **Conflict Avoidance**: Seconds-of-day precision prevents version collisions
- **Marketing Value**: Creative names create brand identity (e.g., Ubuntu's naming strategy)
- **Audit Trail**: Version directly encodes release date for support and debugging
- **Simplified Changelog**: Chronological ordering aligns with development timeline

### Negative
- **Breaking Change Identification**: No explicit signal when API changes break compatibility
- **Naming Overhead**: Requires selecting creative names for major milestones
- **Tooling Support**: May require custom parsing in version comparison tools
- **User Confusion**: Non-traditional format may confuse users expecting SemVer

### Risks
- **Name Collision**: Must maintain registry of used creative names
- **Timezone Misalignment**: Inconsistent timezone usage could cause ordering issues
- **Semantic Drift**: Without compatibility signals, users may struggle to assess upgrade safety
- **Long-term Maintenance**: Year changeover or century rollover concerns (mitigated by four-digit year)

## Implementation Notes

**Version Generation**:
```bash
# Generate version string
YEAR=$(date -u +%Y)
CREATIVE_NAME="Phoenix"  # From release metadata
MMDD=$(date -u +%m%d)
SECONDS_OF_DAY=$(date -u +%s)
SECONDS_OF_DAY=$((SECONDS_OF_DAY % 86400))
VERSION="${YEAR}_${CREATIVE_NAME}_${MMDD}.${SECONDS_OF_DAY}"
echo "$VERSION"  # Output: 2026_Phoenix_0213.54321
```

**Creative Name Selection**:
- Maintain a curated list in project documentation
- Use theme-based naming (e.g., mythological, astronomical, geographical)
- Assign names to major milestones or quarterly releases
- Reuse creative name for all releases within the same period (month/quarter)

**Version Comparison**:
```bash
# Lexicographic comparison works due to year-first format
[[ "2026_Phoenix_0213.54321" > "2026_Aurora_0115.12345" ]] && echo "Phoenix is newer"
```

**Git Tagging**:
```bash
git tag -a "v2026_Phoenix_0213.54321" -m "Release Phoenix (2026-02-13)"
```

**Changelog Grouping**:
- Group releases by creative name or month
- Include full timestamp for precise release identification
- Document breaking changes explicitly in release notes

## Related Items

- [ADR-0001](ADR_0001_bash_as_primary_implementation_language.md) - Bash scripting enables straightforward version generation
- [Project Vision](../../01_project_vision/01_vision.md) - Versioning supports rapid development and user communication goals
- TC-0002: Release Automation (technical constraint - if exists)

**Trade-offs Accepted**:
- **Memorability over Compatibility Signals**: Prioritize human-friendly naming over explicit backward compatibility indicators
- **Temporal Precision over Simplicity**: Accept longer version strings for precise release timestamps
- **Automation over Convention**: Choose automated timestamp generation over manual SemVer bumping
- **Brand Identity over Standardization**: Leverage creative naming for product identity despite non-standard format

## Migration Strategy

**Existing Versions**: 
- If migrating from SemVer, document mapping (e.g., `v1.2.3` → `2026_Genesis_0115.0`)
- Maintain changelog showing correspondence between old and new versioning

**Communication**:
- Document versioning pattern in README and user-facing documentation
- Provide examples in release notes
- Create FAQ section addressing version comparison and compatibility

**Tooling Updates**:
- Update CI/CD pipelines to generate version strings automatically
- Modify packaging scripts to parse new format
- Update documentation generation to handle new version format

