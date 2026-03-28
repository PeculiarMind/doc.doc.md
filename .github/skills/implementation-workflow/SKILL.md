---
name: implementation-workflow
description: "Use when: implementing a backlog item end-to-end, running TDD cycles, executing quality gates (tester, architect, security, license, documentation), or managing the planning board from backlog to done."
---

# Implementation Workflow

## Step 1 — Preflight Test Suite Execution
**Agent:** developer  
**Action:** Run the full test suite before starting new work. If tests fail, assign investigation to tester. Wait for green before proceeding.  
**Output:** Test execution status.  
**Next:** Work Item Selection.

## Step 2 — Work Item Selection
**Agent:** developer  
**Action:** BUG-free principle — pick bugs first, then features. Resolve dependencies; pick highest priority. Move item to `05_implementing`, update status, commit. Create a TASK work item for TDD and assign to tester.  
**Input:** `project_management/03_plan/02_planning_board/04_backlog/`  
**Output:** Work item moved, TASK created and assigned to tester.  
**Next:** TDD Workflow Execution.

## Step 3 — TDD Workflow Execution
**Agent:** tester  
**Action:** Pick the TDD task. Write tests for the feature. Ensure tests fail (red phase). Move TDD task to done, commit. Hand off to developer.  
**Input:** TDD task work item.  
**Output:** Tests implemented (red), TDD task closed, handoff to developer.  
**Next:** Implementation.

## Step 4 — Implementation
**Agent:** developer  
**Action:** Implement the feature. Ensure all related tests pass (green phase). Move work item to done, commit.  
**Input:** Assigned feature work item.  
**Output:** Feature implemented, tests green, work item closed.  
**Next:** Tester Assessment.

## Step 5 — Assessment by Tester
**Agent:** tester  
**Action:** Verify all tests pass and the feature meets requirements. If not, create a BUG in the backlog and assign to developer. If passing, write test report, update work item, commit.  
**Input:** Completed feature work item.  
**Output:** Test report in `project_management/04_reporting/02_tests_reports/`, work item updated.  
**Next:** Architect Assessment.

## Step 6 — Assessment by Architect
**Agent:** architect  
**Action:** Verify implementation aligns with architecture vision. If not, create a DEBTR and TASK in the backlog for remediation. Update work item and commit.  
**Input:** Work item, source code, architecture vision docs.  
**Output:** Compliance result documented in work item.  
**Next:** Security Assessment.

## Step 7 — Security Assessment
**Agent:** security  
**Action:** Verify no security vulnerabilities are introduced. If issues found, create BUG in backlog for developer. If clear, update work item and commit.  
**Input:** Work item, source code, security concept.  
**Output:** Security status documented in work item.  
**Next:** License Governance Assessment.

## Step 8 — License Governance Assessment
**Agent:** license  
**Action:** Review code changes, dependencies, and assets for license compatibility. Document findings. Hand back to developer with Pass/Review/Fail.  
**Input:** Work item, source code, dependency list, third-party assets.  
**Output:** Compliance status in work item.  
**Next:** Documentation Assessment.

## Step 9 — Documentation Assessment
**Agent:** documentation  
**Action:** Verify README.md and user docs reflect the implemented changes. Update if needed. Document in work item.  
**Input:** Work item, current README.md, recent changes summary.  
**Output:** Docs updated, assessment in work item.  
**Next:** Return to Step 2 (Work Item Selection).
