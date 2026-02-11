# Requirement: Workspace Format Version Migration

**ID**: req_0044

## Status
State: Obsoleted  
Created: 2026-02-09  
Last Updated: 2026-02-11

**Obsoleted By**: req_0059 (Workspace Recovery and Rescan)

## Overview
The system shall detect workspace format version mismatches and provide migration mechanisms to upgrade obsolete workspace formats to the current schema.

## Description
Requirement req_0032 mentions workspace version checking and format migration, but does not fully specify the migration mechanism. The Workspace Concept (08_0002) defines workspace schema versioning with `.workspace_version` file and `workspace.json` metadata. As the toolkit evolves, workspace JSON schema may change (new fields, restructured data, different formats). The system must: detect workspace format version on startup, compare against current expected version, migrate data from old formats to new formats when possible, provide clear error messages when migration is impossible, and preserve original data during migration (backup). Migration should be automatic when safe, or require explicit user confirmation for potentially lossy migrations.

## Motivation
From Workspace Concept (08_0002_workspace_concept.md):
```
workspace/
├── .workspace_version       # Workspace schema version
└── metadata.json            # Optional: workspace-level metadata
```

From req_0032: "Workspace version is checked for compatibility with current tool version" and "Obsolete workspace format versions can be migrated to current format."

Users upgrading the toolkit should not lose existing workspace data. Without migration, users face: manual workspace recreation (losing incremental analysis state), errors when mixing old/new formats, or maintenance of outdated toolkit versions.

## Category
- Type: Functional
- Priority: Medium

## Acceptance Criteria

### Version Detection
- [ ] System reads `.workspace_version` file (or `metadata.json` version field) on workspace initialization
- [ ] If version file missing, treats workspace as version 0 (pre-versioning)
- [ ] Current toolkit version defines expected workspace schema version (hardcoded constant)
- [ ] Workspace format version follows semantic versioning (MAJOR.MINOR.PATCH)

### Compatibility Checking
- [ ] System compares workspace version against expected version
- [ ] Exact match: no migration needed, proceed normally
- [ ] Minor version difference (e.g., 1.0 vs 1.1): automatic migration if possible
- [ ] Major version difference (e.g., 1.x vs 2.x): require user confirmation before migration
- [ ] Future version detected (workspace newer than toolkit): error with upgrade recommendation

### Migration Execution
- [ ] System creates backup of workspace directory before migration (`.backup-YYYYMMDD-HHMMSS/`)
- [ ] Migration applies transformations to JSON files (add missing fields, restructure data, rename fields)
- [ ] Migration is idempotent (running twice produces same result)
- [ ] Migration updates `.workspace_version` file to current version after successful migration
- [ ] Migration progress logged (which files migrated, transformations applied)

### Migration Safety
- [ ] Original workspace data backed up before migration starts
- [ ] Migration rollback available if migration fails (restore from backup)
- [ ] Partial migration failures handled gracefully (some files migrated, some failed)
- [ ] Migration validation checks data integrity after migration (JSON valid, required fields present)
- [ ] User can abort migration with clear instructions on rollback

### Migration Strategies
- [ ] **Additive changes** (new optional fields): automatic migration, no user confirmation
- [ ] **Renaming fields**: automatic migration with field mapping
- [ ] **Removing fields**: automatic migration, deprecated fields dropped with warning
- [ ] **Changing field types**: requires user confirmation, potential data loss
- [ ] **Schema restructuring**: requires user confirmation, complex transformation

### Error Handling
- [ ] Incompatible workspace version blocks analysis with clear error message
- [ ] Error message includes: current version, expected version, migration options
- [ ] Migration failures logged with specific error details (which file, what transformation failed)
- [ ] Failed migration preserves backup, provides rollback instructions
- [ ] Users can force analysis ignoring version mismatch (at their own risk via flag)

### User Experience
- [ ] Migration prompts include clear explanation of what will change
- [ ] Migration prompts show estimated time and backup size
- [ ] Non-interactive mode (cron jobs) uses automatic migration for minor versions, fails for major versions
- [ ] Verbose mode logs migration details (version transitions, transformations)
- [ ] Migration completion message includes new version and backup location

## Related Requirements
- req_0032 (Workspace Directory Management) - defines workspace structure and versioning
- req_0025 (Incremental Analysis) - migration preserves incremental analysis state
- req_0018 (Per-File Reports) - workspace JSON format affects reports

## Technical Considerations

### Version File Format
```
# .workspace_version
1.2.0
```

Or in metadata.json:
```json
{
  "workspace_version": "1.2.0",
  "created": "2026-01-15T10:00:00Z",
  "toolkit_version": "1.0.0"
}
```

### Migration Function Structure
```bash
migrate_workspace() {
  local workspace_dir="$1"
  local from_version="$2"
  local to_version="$3"
  
  log "INFO" "Migrating workspace from v${from_version} to v${to_version}"
  
  # Create backup
  local backup_dir="${workspace_dir}/.backup-$(date +%Y%m%d-%H%M%S)"
  cp -r "${workspace_dir}" "${backup_dir}"
  log "INFO" "Backup created at ${backup_dir}"
  
  # Apply migrations based on version transitions
  if [[ "$from_version" == "1.0.0" ]] && [[ "$to_version" == "1.1.0" ]]; then
    migrate_1_0_to_1_1 "$workspace_dir"
  elif [[ "$from_version" == "1.1.0" ]] && [[ "$to_version" == "2.0.0" ]]; then
    migrate_1_1_to_2_0 "$workspace_dir"
  fi
  
  # Update version file
  echo "$to_version" > "${workspace_dir}/.workspace_version"
  
  # Validate migration
  validate_workspace_format "$workspace_dir" "$to_version"
  
  log "INFO" "Migration complete"
}
```

### Example Migration: Adding New Field
```bash
# Migration from 1.0 to 1.1: Add checksum field
migrate_1_0_to_1_1() {
  local workspace_dir="$1"
  
  for json_file in "${workspace_dir}"/*.json; do
    [ -f "$json_file" ] || continue
    
    # Add checksum field if missing
    if ! jq -e '.file_checksum' "$json_file" >/dev/null; then
      local file_path=$(jq -r '.file_path' "$json_file")
      local checksum=$(sha256sum "$file_path" | cut -d' ' -f1)
      
      jq --arg checksum "$checksum" \
         '. + {file_checksum: $checksum}' \
         "$json_file" > "${json_file}.tmp"
      
      mv "${json_file}.tmp" "$json_file"
      log "DEBUG" "Added checksum to $json_file"
    fi
  done
}
```

### Version Compatibility Matrix
| Workspace Version | Toolkit Version | Action |
|-------------------|-----------------|--------|
| 1.0.x | 1.0.x | Compatible, no migration |
| 1.0.x | 1.1.x | Auto-migrate (minor bump) |
| 1.x | 2.x | Confirm migration (major bump) |
| 2.x | 1.x | Error: upgrade toolkit |
| Missing | Any | Treat as v0, migrate to current |

## Transition History
- [2026-02-09] Created in funnel by Requirements Engineer Agent - extracted from Workspace Concept and req_0032 analysis
- [2026-02-09] Moved to analyze for detailed analysis
- [2026-02-09] Moved to accepted by user - ready for implementation
- [2026-02-11] Moved to obsoleted by user  
-- Comment: Migrations are not required; workspace can be rebuilt by rescan
