# MVP Implementation Plan

## Goal
Working MVP that includes:
- **stat plugin execution** (file size, owner, timestamps)
- **ocrmypdf plugin execution** (OCR for PDFs)
- **MD sidecar file creation** for each processed file (e.g., `example.pdf` → `example.md`)

---

## Current State Analysis

### ✅ Already Implemented (Done)
| Component | Status | Notes |
|-----------|--------|-------|
| Basic Script Structure | Done | `scripts/doc.doc.sh` with modular components |
| Plugin Discovery & Validation | Done | `plugin_discovery.sh`, `plugin_validator.sh` |
| Plugin Execution Engine | Done | Dependency graph, Kahn's algorithm, sandbox support |
| stat Plugin | Done | `scripts/plugins/ubuntu/stat/` - provides file_size, file_owner, file_last_modified |
| ocrmypdf Plugin | Done | `scripts/plugins/ubuntu/ocrmypdf/` - provides ocr_confidence, ocr_status, ocr_text_content |
| Directory Scanner | Done | `scanner.sh` - recursive file discovery |
| Workspace Management | Done | `workspace.sh` - JSON storage per file hash |
| Template Engine | Done | `template_engine.sh` - variable substitution, conditionals, loops |
| Report Generator | Done | `report_generator.sh` - generates MD from workspace JSON |
| File Type Filtering | Done | Plugin-to-file matching by MIME type and extension |
| Plugin Results Aggregation | Done | `orchestrate_plugins()` captures output, saves to workspace |

### 🔶 Implemented but Needs Enhancement for MVP
| Component | Gap | Required Change |
|-----------|-----|-----------------|
| Report Naming | Reports named `<hash>.md` | Need `<original_filename>.md` sidecar files |
| Directory Structure | Flat output | Mirror source directory structure |
| Workspace Metadata | Missing relative path | Store source path info for proper naming |
| Default Template | Limited variables | Use all plugin-provided variables |

---

## Implementation Phases

### Phase 1: Report Generation Enhancement (CRITICAL)
**Feature**: feature_0049_final_report_generation
**Priority**: Critical for MVP
**Effort**: Medium

#### Changes Required:
1. **Store source file path in workspace JSON** (`orchestrate_plugins`)
   - Add `file_path`, `filepath_relative`, `source_directory` to workspace data
   - This enables proper sidecar naming and directory mirroring

2. **Modify `generate_reports()` in report_generator.sh**
   - Read `filepath_relative` from workspace JSON
   - Create output subdirectories mirroring source structure
   - Name reports as `<basename>.md` instead of `<hash>.md`

3. **Update `render_report()` to populate all template variables**
   - Expose file_size, file_owner, file_last_modified from stat plugin
   - Expose ocr_* fields from ocrmypdf plugin

#### Acceptance Criteria:
- [ ] `source/docs/report.pdf` → `output/docs/report.md`
- [ ] `source/image.png` → `output/image.md`
- [ ] Directory hierarchy preserved in output
- [ ] Template variables populated from plugin results

---

### Phase 2: Workspace Metadata Enhancement (HIGH)
**Priority**: Required for Phase 1
**Effort**: Low

#### Changes Required:
1. **Enhance `orchestrate_plugins()` in plugin_executor.sh**
   ```bash
   # Store these in workspace data:
   - file_path: absolute path
   - filepath_relative: relative to source directory
   - source_directory: root scan directory
   - filename: basename of file
   ```

2. **Pass source directory context to save_workspace**
   - Modify `execute_analysis_workflow()` to pass `$source_dir` context

---

### Phase 3: Template Enhancement (MEDIUM)
**Priority**: Improves MVP quality
**Effort**: Low

#### Update `scripts/templates/default.md`:
```markdown
# ${filename}

## File Information
- **Path:** ${filepath_relative}
- **Size:** ${file_size} bytes (${file_size_human})
- **Owner:** ${file_owner}
- **Last Modified:** ${file_last_modified}

## Analysis
- **Last Analyzed:** ${generation_time}
- **Plugins Executed:** ${plugins_executed_count}

{{#if ocr_status}}
## OCR Results
- **Status:** ${ocr_status}
- **Confidence:** ${ocr_confidence}%

### Extracted Text
${ocr_text_content}
{{/if}}
```

---

### Phase 4: Error Handling (LOWER for MVP)
**Feature**: feature_0050_comprehensive_error_handling
**Priority**: Nice to have
**Effort**: Medium

Can defer for MVP - current error handling is functional.

---

### Phase 5: Security Features (FUTURE)
**Features**: feature_0045_file_type_validation, feature_0026_plugin_execution_sandboxing
**Priority**: Post-MVP
**Effort**: High

Important for production but not blocking MVP.

---

## Implementation Order

```
┌─────────────────────────────────────────────────────────────────────┐
│ MVP Critical Path                                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Step 1: Workspace Metadata (Phase 2)                               │
│    └── Store file paths in workspace JSON                           │
│         Duration: ~1 hour                                           │
│                                                                     │
│  Step 2: Report Generation (Phase 1)                                │
│    └── Sidecar file naming + directory mirroring                    │
│         Duration: ~2 hours                                          │
│                                                                     │
│  Step 3: Template Update (Phase 3)                                  │
│    └── Expose all plugin variables                                  │
│         Duration: ~30 min                                           │
│                                                                     │
│  Step 4: End-to-End Testing                                         │
│    └── Verify full workflow with sample PDFs and files              │
│         Duration: ~1 hour                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/components/plugin/plugin_executor.sh` | Add source path metadata to workspace |
| `scripts/components/orchestration/main_orchestrator.sh` | Pass source_dir context through workflow |
| `scripts/components/orchestration/report_generator.sh` | Implement sidecar naming + directory mirroring |
| `scripts/templates/default.md` | Add all plugin-provided variable placeholders |

---

## Backlog Items for MVP

### Must Have (MVP Blocking)
1. ~~feature_0048_plugin_results_aggregation~~ - **Already implemented** in `orchestrate_plugins()`
2. **feature_0049_final_report_generation** - Needs enhancement (sidecar naming)

### Should Have (MVP Quality)
3. ~~feature_0044_plugin_file_type_filtering~~ - **Already implemented**
4. ~~feature_0047_file_plugin_assignment~~ - **Already implemented** via `should_execute_plugin()`

### Could Have (Post-MVP)
5. feature_0050_comprehensive_error_handling - Enhance error recovery
6. feature_0045_file_type_validation - Security hardening

### Won't Have (Future)
7. feature_0026_plugin_execution_sandboxing - Full sandbox (bwrap already partially implemented)
8. feature_0051_bogofilter_plugin - Additional plugin
9. feature_0052_plugin_command_execution - Plugin sub-commands

---

## Estimated Total MVP Effort

| Phase | Effort | Cumulative |
|-------|--------|------------|
| Phase 2: Workspace Metadata | 1 hour | 1 hour |
| Phase 1: Report Generation | 2 hours | 3 hours |
| Phase 3: Template | 30 min | 3.5 hours |
| Testing & Validation | 1 hour | 4.5 hours |
| **Total** | | **~4-5 hours** |

---

## Verification Checklist

After implementation, verify:

```bash
# 1. Create test directory structure
mkdir -p /tmp/test_source/subdir
echo "test" > /tmp/test_source/file.txt
cp sample.pdf /tmp/test_source/subdir/document.pdf

# 2. Run analysis
./scripts/doc.doc.sh -d /tmp/test_source -w /tmp/workspace -t /tmp/output -m scripts/templates/default.md -v

# 3. Verify output structure mirrors source
ls -la /tmp/output/
# Expected: file.md
ls -la /tmp/output/subdir/
# Expected: document.md

# 4. Verify report content contains plugin data
cat /tmp/output/file.md
# Should contain: file_size, file_owner, file_last_modified

cat /tmp/output/subdir/document.md
# Should contain: ocr_status, ocr_confidence (if ocrmypdf available)
```

---

## Dependencies Between Backlog Items

```
feature_0047 (File-Plugin Assignment)
     │
     └──► feature_0048 (Results Aggregation) ─► feature_0049 (Final Report Generation)
                                                        │
                                                        ▼
                                                   [MVP COMPLETE]
                                                        │
                                                        ▼
                                              feature_0050 (Error Handling)
                                                        │
                                                        ▼
                                              feature_0045 (Security)
```

**Note**: feature_0047 and feature_0048 are essentially complete. The primary work is in feature_0049 (sidecar file generation with proper naming).

---

## Conclusion

The MVP is close to completion. The core infrastructure is in place:
- Plugins execute and provide data ✅
- Results aggregate to workspace JSON ✅
- Reports generate from templates ✅

**The single critical gap is sidecar file naming and directory structure mirroring** in `report_generator.sh`. Once that's implemented, the MVP will be functional.
