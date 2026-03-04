# Quality Requirements

Quality requirements are organized by priority, from the quality tree in the architecture vision. Scenarios are concrete and measurable.

## Quality Tree

```
                    Quality
          ┌──────────┼──────────┐
      Usability  Flexibility  Reliability
      (P1)       (P2)         (P3)
          │           │           │
    Maintainability  Compatibility  Performance
    (P4)             (P5)
```

## Usability (Priority 1)

| ID | Scenario | Measure |
|----|----------|---------|
| QS-U01 | New user runs `doc.doc.sh --help` | Clear help with examples; basic usage understood in < 2 minutes |
| QS-U02 | User provides non-existent input directory | Error: `"Input directory '/path' does not exist"` with actionable hint; no documentation lookup needed |
| QS-U03 | User wants to process PDFs | Single command: `doc.doc.sh process -d /input -i ".pdf"` — no documentation required |
| QS-U04 | User unsure which commands exist | `--help` lists all commands with descriptions; all discoverable from CLI alone |
| QS-U05 | User makes filter syntax error | Error identifies the invalid parameter and shows a correct-syntax example |

## Flexibility (Priority 2)

| ID | Scenario | Measure |
|----|----------|---------|
| QS-F01 | Developer adds a new file type handler | Drop plugin directory with `descriptor.json` into `plugins/`; no core modification required |
| QS-F02 | User needs PDFs from 2024, excluding temp dirs | `doc.doc.sh process -d /input -i ".pdf" -i "**/2024/**" -e "**/temp/**"` — all 8 documented filter examples work correctly |
| QS-F03 | User wants custom markdown output format | `--template /path/to/template.md` — applied without code changes |
| QS-F04 | Plugin requires output from another plugin | `mimeType` input in `ocrmypdf` satisfied by `file` plugin output — execution order resolved automatically |
| QS-F05 | User wants to activate only specific plugins | `activate`/`deactivate` commands control the chain; inactive plugins produce no output |

## Reliability (Priority 3)

| ID | Scenario | Measure |
|----|----------|---------|
| QS-R01 | Plugin dependency tool not installed | `installed.sh` returns `false`; clear error: dependency missing; processing continues with other plugins |
| QS-R02 | File has no read permissions | Warning logged to stderr; file skipped; processing continues; skipped count in summary |
| QS-R03 | Plugin `process` exits with code 1 | Error logged with plugin name and file path; processing continues |
| QS-R04 | Template variable not populated by any plugin | Variable replaced with empty string or default; warning logged; document still generated |
| QS-R05 | Processing 10,000+ files | Streaming `find` pipeline; memory constant regardless of file count; < 100 MB RSS |

## Maintainability (Priority 4)

| ID | Scenario | Measure |
|----|----------|---------|
| QS-M01 | New developer reads `doc.doc.sh` | Clear function names, comments, separation of concerns; workflow understood in < 30 minutes |
| QS-M02 | Bug found in include/exclude logic | All filter logic in `filter.py` with unit tests; fix isolated to a single file |
| QS-M03 | New subcommand needed | Add `cmd_<name>()` function and route in `main()`; < 50 lines; no refactoring |
| QS-M04 | Plugin descriptor schema changes | Schema documented in ADR-003; impact discoverable via `grep "descriptor"` |
| QS-M05 | Architecture changes require doc update | Arc42 structure; update confined to the relevant section |

## Compatibility (Priority 5)

| ID | Scenario | Measure |
|----|----------|---------|
| QS-C01 | Tool run on macOS | `stat` plugin uses BSD flags; `file` plugin uses portable flags; all core features work |
| QS-C02 | User opens generated markdown in Obsidian | All markdown renders correctly; no Obsidian-specific errors |
| QS-C03 | Tool run on Ubuntu, Fedora, Arch | No distribution-specific failures |
| QS-C04 | System has Python 3.12 (minimum) | `filter.py` runs without import errors or deprecation warnings |
| QS-C05 | POSIX shell compliance | Core shell logic uses POSIX-compatible constructs |

## Performance

| ID | Scenario | Measure |
|----|----------|---------|
| QS-P01 | Any command | First output within < 1 second of invocation |
| QS-P02 | 10-file directory | Total processing < 5 seconds (excluding plugin execution time) |
| QS-P03 | 1000-file directory | < 100 ms overhead per file in the processing loop |
| QS-P04 | Complex filter (5 include + 5 exclude params) | Filter evaluation < 10 ms per file |
| QS-P05 | 3 plugins per file | Plugin chain overhead (excluding plugin execution) < 50 ms |

## Security

| ID | Scenario | Measure |
|----|----------|---------|
| QS-S01 | Input path contains `../../../` | Path canonicalized; no access outside intended directory |
| QS-S02 | Template variable contains shell commands | Variables escaped before substitution; no command execution via templates |
| QS-S03 | Malicious plugin descriptor loaded | Descriptor validated against schema; invalid descriptors rejected with error |
| QS-S04 | Plugin attempts to access core system files | Plugins run with user permissions; documented best-practice guidance provided |
| QS-S05 | Malformed JSON sent to plugin | JSON validated against descriptor schema before plugin execution |
| QS-S06 | Oversized JSON payload | Size limits enforced (max 1 MB) to prevent DoS |
