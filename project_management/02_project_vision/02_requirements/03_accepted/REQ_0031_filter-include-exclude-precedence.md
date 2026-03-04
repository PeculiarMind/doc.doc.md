# Requirement: Filter Include/Exclude Evaluation Precedence

- **ID:** REQ_0031
- **State:** Accepted
- **Type:** Functional
- **Priority:** High
- **Created at:** 2026-03-04
- **Last Updated:** 2026-03-04

## TOC

## Overview
Include filters must be evaluated before exclude filters; exclude filters reduce — but never extend — the candidate set produced by include evaluation.

## Description
When the `doc.doc.sh process` command applies filtering, evaluation proceeds in two strictly ordered steps:

1. **Step 1 — Include evaluation**: The include filters determine the candidate set of files to process. If no `--include` parameters are given, all files in the input directory are candidates.
2. **Step 2 — Exclude evaluation**: The exclude filters are applied to the candidate set produced in Step 1, removing any files that match the exclude criteria. If no `--exclude` parameters are given, no files are removed.

Exclude filters can only remove files from the candidate set. They cannot add files back, nor can they override the include result in a permissive direction. This two-phase evaluation ensures predictable, deterministic filtering behaviour regardless of the number or combination of `--include` and `--exclude` parameters supplied.

## Motivation
- [Project Goals — Input Gathering Phase](../../01_project_goals/project_goals.md#processing-documents)
- [Project Goals — Filter Logic](../../01_project_goals/project_goals.md#example-explanation)

## Acceptance Criteria
- [ ] When include filters are specified, only files matching the include criteria form the candidate set before exclude evaluation.
- [ ] When no include filters are specified, all files in the input directory form the candidate set before exclude evaluation.
- [ ] Exclude filters remove files from the candidate set; they do not add files.
- [ ] The final processed set equals: (include candidate set) MINUS (files matching exclude criteria).
- [ ] The two-phase evaluation order is preserved regardless of the order `--include` and `--exclude` arguments appear on the command line.

## Related Requirements
- [REQ_SEC_002](REQ_SEC_002_filter_logic_correctness.md) — Filter Logic Correctness and Security
- [REQ_0009](REQ_0009_process-command.md) — Process Command
