# Architecture Review: BUG_0005 — Remove `dependencies` Attribute from Plugin Descriptors

- **ID:** ARCHREV_005
- **Created at:** 2026-03-06
- **Created by:** architect.agent
- **Work Item:** [BUG_0005](../../03_plan/02_planning_board/06_done/BUG_0005_plugin_descriptor_explicit_dependencies_attribute.md)
- **Status:** Compliant

## TOC

1. [Reviewed Scope](#reviewed-scope)
2. [Architecture Vision Reference](#architecture-vision-reference)
3. [Compliance Assessment](#compliance-assessment)
4. [Deviations Found](#deviations-found)
5. [Recommendations](#recommendations)
6. [Conclusion](#conclusion)

## Reviewed Scope

| File | Change | Purpose |
|------|--------|---------|
| `doc.doc.md/plugins/ocrmypdf/descriptor.json` | Modified | Removed `"dependencies"` field |
| `doc.doc.sh` — `cmd_tree()` | Modified | Re-implemented dependency derivation via output→input parameter matching |

Also verified: no other plugin descriptors contain a `"dependencies"` field.

## Architecture Vision Reference

- [ADR-003: JSON-Based Plugin Descriptors with Shell Command Invocation](../../02_project_vision/03_architecture_vision/09_architecture_decisions/ADR_003_json_plugin_descriptors.md)
- [ARC-0003: Plugin Architecture Concept](../../02_project_vision/03_architecture_vision/08_concepts/ARC_0003_plugin_architecture.md)

## Compliance Assessment

| Area | Status | Notes |
|------|--------|-------|
| **ADR-003 — No `dependencies` field in descriptor** | ✅ Compliant | ADR-003 change history explicitly records: "Removed `dependencies` field — dependencies discovered automatically by analyzing input/output parameters between plugins." The `ocrmypdf/descriptor.json` no longer contains a `"dependencies"` key. |
| **ADR-003 — Descriptor schema integrity** | ✅ Compliant | The remaining fields in `ocrmypdf/descriptor.json` (`name`, `version`, `description`, `active`, `commands`) conform to the canonical ADR-003 schema. The descriptor is valid JSON. |
| **ARC-0003 — Dependency derivation algorithm** | ✅ Compliant | `cmd_tree()` performs a two-pass algorithm: (1) collect each active plugin's `process.output` parameter names, (2) for each plugin, identify which other plugins supply its `process.input` parameters via name matching. Plugin A depends on Plugin B if at least one of B's output parameter names matches one of A's input parameter names. This implements ARC-0003's "Build dependency graph from descriptors / Perform topological sort" specification. |
| **ARC-0003 — Circular dependency detection** | ✅ Compliant | `cmd_tree()` contains a DFS-based cycle detection function (`_detect_cycle`). A circular dependency causes an immediate error with exit code 1 and an informative error message to stderr. |
| **ARC-0003 — ocrmypdf→file chain preserved** | ✅ Compliant | `ocrmypdf/process` declares `mimeType` as an input parameter. `file/process` declares `mimeType` as an output parameter. The name-matching algorithm correctly derives the dependency edge `ocrmypdf → file` without any explicit annotation in the descriptors. |
| **Single source of truth** | ✅ Compliant | The descriptor's `input`/`output` blocks are now the sole authoritative source for dependency information. There is no longer a second, potentially conflicting `dependencies` attribute. |
| **Existing behaviour preserved** | ✅ Compliant | The `discover_plugins()` function and the `process` command's ordered plugin execution continue to resolve the `file`-first constraint and the `ocrmypdf → file` dependency chain as before. |

## Deviations Found

None.

## Recommendations

1. **Document the algorithm in ARC-0003**: The current ARC-0003 concept references dependency resolution at a high level ("Build dependency graph from descriptors") but does not describe the name-matching algorithm now implemented in `cmd_tree()`. A brief note in ARC-0003 — or an update to the "Plugin Dependency Resolution" section — would make this design decision explicit and help future plugin authors understand why choosing unique, meaningful output parameter names matters.

2. **Consider naming collision guidance**: If two plugins produce an output parameter with the same name, any plugin that accepts that name as input will be treated as depending on both. This is currently unspecified behaviour. The implementation handles it gracefully (both become dependencies), but a note in plugin development guidelines would prevent confusion.

## Conclusion

BUG_0005 is **fully compliant** with the architecture vision. The `dependencies` field — which ADR-003 explicitly forbids — has been removed from the one descriptor that contained it. The replacement algorithm in `cmd_tree()` correctly derives plugin dependency edges by matching output parameter names to input parameter names, consistent with ADR-003 and ARC-0003. The existing `ocrmypdf → file` dependency chain is correctly preserved by the new algorithm, and circular dependency detection prevents invalid configurations.

**Result: PASS**
