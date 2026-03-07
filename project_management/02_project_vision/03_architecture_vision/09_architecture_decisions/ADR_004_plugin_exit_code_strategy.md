# Plugin Exit Code and Failure Handling Strategy

- **ID:** ADR-004
- **Status:** DECIDED
- **Created at:** 2026-03-07
- **Created by:** Architect Agent
- **Decided at:** 2026-03-07
- **Decided by:** Architecture Review
- **Obsoleted by:** N/A

# Change History
| Date | Author | Description |
|------|--------|-------------|
| 2026-03-07 | Architect Agent | Initial decision document |

# TOC

1. [Context](#context)
2. [Decision](#decision)
3. [Consequences](#consequences)
4. [Alternatives Considered](#alternatives-considered)
5. [Evaluation Matrix](#evaluation-matrix)
6. [References](#references)

# Context

## Background

Following ADR-003, plugins communicate with the `doc.doc.sh` framework via JSON on stdin/stdout and exit codes. The framework's `run_plugin` / `process_file` functions in `plugin_execution.sh` use the plugin's exit code to decide whether an invocation succeeded or failed and whether to print an error to the user.

## Problem

Plugins such as `markitdown` and `ocrmypdf` are designed to process specific MIME types. When invoked with a file they do not support, they currently exit with code 1 (generic failure). The framework has no way to distinguish this expected, intentional decline from a genuine processing error. The result: the user sees spurious error messages:

```
Error: Plugin 'markitdown' failed for file: README-Screenshot-PNG.png
```

This is misleading. No failure occurred — the plugin simply chose not to process that file. A well-defined exit code contract is needed to make this distinction machine-readable.

## Design Constraints

- Plugins may be written in any language (Bash, Python, or other). The contract must be language-agnostic.
- The framework (Bash) consumes the exit code. Parsing must be trivial.
- The contract must be stable enough to become a public plugin authoring convention.
- The chosen exit codes should follow established UNIX standards where possible.
- The JSON stdout contract (ADR-003) must remain intact for the success case.

## Alternatives Considered

### Approach A — Exit 0 for All, Skip Signal Via JSON Shape

A plugin always exits 0. A "skip" is signalled by returning `{}` or `{"message": "..."}` as stdout. The framework detects a skip by inspecting the JSON key count.

**Problem:** Distinguishing skip from success requires JSON parsing before the framework knows the outcome. Any JSON parse failure (e.g., a stray warning line printed before the JSON) falls through to an ambiguous state. The exit code carries no semantic content, requiring the framework to do more work per invocation.

### Approach B — Structured Exit Codes (BSD sysexits.h)

Define a small, stable set of semantically meaningful exit codes aligned with the BSD `sysexits.h` standard (established in 4.3BSD, codified in FreeBSD's `/usr/include/sysexits.h`):

| Code | Constant         | Meaning in plugin context |
|------|------------------|---------------------------|
| 0    | `EX_OK`          | Successful execution; JSON output contains plugin results |
| 65   | `EX_DATAERR`     | Input file not supported / cannot be processed by this plugin; intentional skip |
| 1    | _(misc failure)_ | Unexpected error during processing |

Exit code 65 (`EX_DATAERR` — "the input data was incorrect in some way") is the closest standard code to "this plugin cannot handle this input type." Using a standard constant improves interoperability and self-documentation.

**Advantages:** Exit code is the single, first-class signal. The framework's decision is a simple integer comparison before any JSON parsing. Plugin intent is unambiguous.

### Approach C — Custom Exit Code for Skip (e.g., exit 2)

Define a project-specific exit code (e.g., 2) for "unsupported input." Avoids overloading a sysexits.h constant.

**Problem:** Invents a non-standard convention with no external reference. Contributors must consult project documentation to understand the meaning. Offers no advantage over Approach B while sacrificing the alignment with a well-known standard.

# Decision

**Adopt Approach B: structured exit codes aligned with BSD `sysexits.h`.**

The plugin exit code contract is:

| Exit Code | Meaning | JSON stdout |
|-----------|---------|-------------|
| **0** | Successful execution | JSON object with output attributes as declared in `descriptor.json` |
| **65** | Input not supported — intentional skip | `{}` or `{"message": "<reason>"}` (optional but recommended) |
| **1** (or any other non-zero ≠ 65) | Unexpected failure during processing | Any (framework will not parse it) |

### Rules for plugins

1. A plugin MUST exit 0 when it has successfully processed the input and produced output JSON.
2. A plugin MUST exit 65 when it has determined that the input is not something it can or will handle (unsupported MIME type, unsupported file structure, etc.). It SHOULD print `{"message": "<human-readable reason>"}` to stdout to aid debugging.
3. A plugin MUST exit with a non-zero code other than 65 (typically 1) when an unexpected error occurs during processing.
4. A plugin MUST NOT exit 65 for errors that occur while attempting to process a supported input type — that is a failure (exit 1), not a skip.

### Rules for the framework

1. Exit 0 → merge stdout JSON into `combined_result`.
2. Exit 65 → silently discard; do not merge; do not print any message to the user.
3. Any other non-zero → print error message to stderr; continue with next plugin.

# Consequences

## Positive
- **Unambiguous signal**: The exit code alone determines framework behaviour before any JSON parsing.
- **Standard-aligned**: Exit 65 maps to a well-known UNIX constant (`EX_DATAERR`), reducing the cognitive overhead for plugin authors familiar with UNIX conventions.
- **Plugin autonomy preserved**: Each plugin decides independently whether it supports a given input. The framework does not pre-screen.
- **No descriptor changes required**: `descriptor.json` gains no new mandatory fields. The skip decision is entirely encapsulated in plugin logic.
- **Minimal framework change**: `run_plugin` gains one extra branch (`elif [ $exit == 65 ]`) and nothing else.
- **Debuggable**: The optional `{"message":"..."}` on exit 65 gives developers a reason when inspecting raw plugin output.

## Negative / Risks
- **Exit 65 convention must be documented**: Plugin authors who are not familiar with this ADR could mistakenly exit 1 for unsupported types. The developer guide must be updated.
- **Not all plugins need updating immediately**: Only plugins with MIME-type restrictions (`markitdown`, `ocrmypdf`) currently exhibit the false-error problem. Other plugins are unaffected.
- **EX_DATAERR semantic stretch**: In strict sysexits.h usage, `EX_DATAERR` means "data format error in input", not "input type not supported". The semantic is close but not identical. The project documentation must clarify the chosen meaning.

# Alternatives Considered

See [Approach A](#approach-a--exit-0-for-all-skip-signal-via-json-shape) and [Approach C](#approach-c--custom-exit-code-for-skip-eg-exit-2) above.

# Evaluation Matrix

| Criterion | Weight | A: Exit 0 + JSON shape | B: sysexits.h codes | C: Custom exit 2 |
|-----------|--------|------------------------|---------------------|------------------|
| **Framework simplicity** (exit code is the only signal needed) | 0.30 | ✗ Requires JSON parse to distinguish skip from success | ✓ One integer comparison | ✓ One integer comparison |
| **Standard alignment** (uses established UNIX conventions) | 0.25 | ✗ Invents new JSON-shape convention | ✓ Aligns with BSD sysexits.h | ✗ Invents project-specific code |
| **Plugin authoring clarity** (easy to implement correctly) | 0.20 | ~ Shape rule is subtle; easy to produce `{}` accidentally | ✓ `exit 65` or `exit $EX_DATAERR` is unambiguous | ~ Clear but obscure without docs |
| **Robustness to JSON parse errors** | 0.15 | ✗ Ambiguous if stdout is not valid JSON | ✓ Exit code checked before JSON parse | ✓ Exit code checked before JSON parse |
| **Backward compatibility** (existing passing plugins unaffected) | 0.10 | ✓ No change for exit-0 plugins | ✓ No change for exit-0 plugins | ✓ No change for exit-0 plugins |
| **Weighted Score** | **/1.00** | **0.325** (33%) | **0.950** (95%) | **0.625** (63%) |

**Legend:**
- ✓ = Strength / Good fit (1.0 point)
- ~ = Acceptable / Trade-off (0.5 points)
- ✗ = Weakness / Poor fit (0.0 points)
- **Weighted Score** = Sum of (rating × weight) across all criteria

# References

- [ARC_0007 Plugin Skip Protocol](../08_concepts/ARC_0007_plugin_mime_type_skip.md)
- [REQ_0039 Silent Skip for Unsupported MIME Types](../../../02_requirements/03_accepted/REQ_0039_silent-skip-unsupported-mime-types.md)
- [ADR-003 JSON-Based Plugin Descriptors](ADR_003_json_plugin_descriptors.md)
- [ARC_0004 Error Handling](../08_concepts/ARC_0004_error_handling.md)
- BSD sysexits.h — FreeBSD `/usr/include/sysexits.h`; also IETF RFC 3463 uses similar structured status codes
- [plugin_execution.sh](../../../../doc.doc.md/components/plugin_execution.sh)
