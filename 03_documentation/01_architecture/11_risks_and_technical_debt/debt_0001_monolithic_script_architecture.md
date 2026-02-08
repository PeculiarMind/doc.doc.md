# DEBT-0001: Monolithic Script Architecture

**ID**: debt-0001  
**Status**: Accepted  
**Priority**: Medium  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

## Description

Current implementation uses single-file architecture (`doc.doc.sh` with all functions in one file) instead of component-based architecture proposed in vision (ADR-0007), which specifies separate component files organized in `scripts/components/` directory.

## Impact

**Current State** (510 lines in single file):
- Manageable for current scope
- Testing requires sourcing entire file
- Limited parallel development capability
- All changes touch same file (potential merge conflicts)

**Future Impact** as features grow:
- **Maintainability**: Harder to navigate and understand as LOC increases
- **Testability**: Cannot test components in isolation without sourcing entire file
- **Collaboration**: Multiple developers editing same file increases merge conflicts
- **Cognitive Load**: Single file with 1000+ lines difficult to comprehend
- **Reusability**: Cannot reuse components in other scripts without copying

## Root Cause

Prioritized deployment simplicity and implementation speed over architectural vision:
- Single file easier to distribute and install
- No sourcing logic complexity during startup
- Faster initial implementation for Feature 0001
- Trade-off accepted: Technical debt for delivery speed

## Mitigation Strategy

**Short Term** (Current - 1000 LOC threshold):
- Continue with single-file approach while script remains under 1000 lines
- Document functions with clear responsibilities
- Maintain modular function design to ease future refactoring
- Monitor file growth and team collaboration friction

**Long Term** (When threshold reached):
1. **Refactor to component-based architecture per ADR-0007**:
   - Create `scripts/components/` directory structure
   - Extract logical groupings into component files:
     - `core/logging.sh` - Logging functionality
     - `core/errors.sh` - Error handling
     - `platform/detection.sh` - Platform detection
     - `plugin/discovery.sh` - Plugin discovery
     - `plugin/listing.sh` - Plugin listing
     - `ui/display.sh` - Display formatting
   - Create loader in `doc.doc.sh` to source components
   - Update tests to work with component structure

2. **Gradual migration approach**:
   - Extract one component at a time
   - Maintain backward compatibility during migration
   - Update tests incrementally
   - Document component contracts

**Threshold Triggers** for refactoring:
- Script exceeds 1000 lines
- Team size grows beyond 2 developers
- Merge conflicts become frequent (>2 per month)
- New features delayed due to code navigation difficulty
- Request to reuse components in other scripts

## Acceptance Criteria

Debt resolved when:
- ✅ All logical components extracted to separate files in `scripts/components/`
- ✅ Component loading logic implemented in main script
- ✅ All tests updated to work with component architecture
- ✅ Documentation updated to reflect new structure
- ✅ No functional regressions introduced
- ✅ Deployment process updated (if needed)

## Related Items

- **Vision**: [ADR-0007: Modular Component-Based Architecture](../../../01_vision/03_architecture/09_architecture_decisions/ADR_0007_modular_component_based_script_architecture.md)
- **Implementation**: [IDR-0001: Modular Function Architecture](../09_architecture_decisions/IDR_0001_modular_function_architecture.md)
- **Requirements**: req_multiple (various requirements will benefit from component architecture)
- **Features**: feature_0001 (Basic Script Structure), future features will increase pressure

## Monitoring Metrics

Track these indicators to determine when refactoring becomes necessary:
- **Lines of Code**: Currently 510, threshold 1000
- **Merge Conflicts**: Currently low (single developer), threshold >2/month
- **Test Execution Time**: Currently acceptable, monitor for growth
- **Developer Onboarding Time**: Time to understand codebase
- **Feature Development Speed**: Track if single-file architecture slows development
