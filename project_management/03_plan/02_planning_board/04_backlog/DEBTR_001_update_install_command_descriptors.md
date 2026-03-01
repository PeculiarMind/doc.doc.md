# Update Install Command Descriptors to Include `message` Output Parameter

- **ID:** DEBTR_001
- **Priority:** LOW
- **Type:** Technical Debt
- **Created at:** 2026-03-01
- **Created by:** architect.agent
- **Assigned to:** developer.agent
- **Status:** BACKLOG

## TOC

1. [Overview](#overview)
2. [Origin](#origin)
3. [Description](#description)
4. [Acceptance Criteria](#acceptance-criteria)
5. [Affected Files](#affected-files)

## Overview

The install command output in both stat and file plugin scripts includes a `message` field that is not declared in the respective `descriptor.json` files. The descriptors should be updated to match the implemented behavior.

## Origin

- **Architecture Review:** [ARCHREV_001](../../../04_reporting/01_architecture_reviews/ARCHREV_001_FEATURE_0002_stat_file_plugins.md)
- **Feature:** [FEATURE_0002](../05_implementing/FEATURE_0002_implement_stat_and_file_plugins.md)
- **Deviation:** DEV-001 — Install command output includes undeclared `message` field

## Description

Both `stat/install.sh` and `file/install.sh` output JSON with two fields: `success` (boolean) and `message` (string). The `message` field was requested in the FEATURE_0002 acceptance criteria but was not added to the plugin descriptors. The descriptor contract should accurately reflect the implemented output to maintain the principle that descriptors serve as self-documentation (ADR-003).

## Acceptance Criteria

- [ ] `doc.doc.md/plugins/stat/descriptor.json` install command output includes `message` parameter with type `string` and description
- [ ] `doc.doc.md/plugins/file/descriptor.json` install command output includes `message` parameter with type `string` and description
- [ ] Updated descriptors remain valid JSON
- [ ] No changes to implementation scripts required

## Affected Files

- `doc.doc.md/plugins/stat/descriptor.json`
- `doc.doc.md/plugins/file/descriptor.json`
