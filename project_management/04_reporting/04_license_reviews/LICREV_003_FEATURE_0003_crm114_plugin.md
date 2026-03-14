# License Review: LICREV_003 — FEATURE_0003 CRM114 Text Classification Plugin

- **ID:** LICREV_003
- **Created at:** 2026-03-14
- **Created by:** license.agent
- **Work Item:** FEATURE_0003 CRM114 Text Classification Plugin
- **Status:** Pass

## Reviewed Scope

New `crm114` plugin (descriptor.json, main.sh, installed.sh, install.sh) implementing text classification using CRM114.

## Findings

| # | Component | License | Compatible | Notes |
|---|-----------|---------|------------|-------|
| 1 | crm114 plugin scripts | AGPL-3.0 (project) | ✅ Yes | New project files |
| 2 | CRM114 Discriminator | GPL-2.0 | ✅ Yes | Invoked as external process, not linked |

## New Dependencies

| Dependency | Version | License | Source | Compatibility |
|------------|---------|---------|--------|---------------|
| CRM114 | System | GPL-2.0 | apt/brew | ✅ Invoked as external subprocess via stdin/stdout. Not linked or bundled. |

## Attribution Requirements

CRM114 is invoked as an external command-line tool via subprocess. Per the GPL-2.0 license:
- No linking occurs (subprocess invocation only)
- No GPL-2.0 obligations propagate to the calling code
- Standard attribution via documentation is sufficient

## Conclusion

**Status: PASS** — CRM114 is invoked as an external process (not linked), so GPL-2.0 obligations do not propagate to the AGPL-3.0 project. No license conflicts.
