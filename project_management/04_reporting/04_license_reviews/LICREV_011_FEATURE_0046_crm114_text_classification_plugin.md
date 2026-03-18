# License Review: FEATURE_0046 — CRM114 Text Classification Plugin

- **Report ID:** LICREV_011
- **Work Item:** FEATURE_0046
- **Date:** 2026-03-18
- **Agent:** license.agent
- **Status:** PASS

## Scope

Review of code changes for FEATURE_0046 (CRM114 text classification plugin) for license compatibility and attribution requirements.

## Reviewed Components

| Component | License | Compatible |
|-----------|---------|------------|
| `doc.doc.md/plugins/crm114/descriptor.json` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/process.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/manageCategories.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/train.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/learn.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/unlearn.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/listCategories.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/install.sh` | AGPL-3.0 | ✅ Yes |
| `doc.doc.md/plugins/crm114/installed.sh` | AGPL-3.0 | ✅ Yes |
| `tests/test_feature_0046.sh` | AGPL-3.0 | ✅ Yes |

## New Dependencies

| Dependency | License | Distribution | Compatible |
|------------|---------|-------------|------------|
| `crm114` (system package — CRM114 Discriminator) | GPL-2.0+ | System-provided, not distributed | ✅ Yes |
| `csslearn` (part of crm114 package) | GPL-2.0+ | System-provided, not distributed | ✅ Yes |
| `cssunlearn` (part of crm114 package) | GPL-2.0+ | System-provided, not distributed | ✅ Yes |
| `crmclassify` (part of crm114 package) | GPL-2.0+ | System-provided, not distributed | ✅ Yes |
| `bash` (shell interpreter) | GPL-3.0+ | System-provided, not distributed | ✅ Yes |
| `jq` (JSON processor) | MIT | System-provided, not distributed | ✅ Yes |

**Note on CRM114 license compatibility:** crm114 is licensed under GPL-2.0+. Since it is a system tool invoked as a subprocess (not linked or bundled), there is no license propagation to this project's AGPL-3.0 code. The project does not distribute crm114 binaries; it only documents that crm114 must be present on the user's system.

## Attribution Requirements

None. All new code is original work authored under the project's AGPL-3.0 license. No third-party algorithms, code snippets, or documentation from external sources were copied.

## Verdict

**PASS** — All changes are original code under the project's AGPL-3.0 license. The crm114 system dependency (GPL-2.0+) is invoked as a subprocess and not distributed, so no license compatibility issue arises. No attribution requirements arise from this feature.
