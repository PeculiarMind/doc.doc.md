### Implementation Workflow 

#### Step 1: Preflight Test Suite Execution
**Agent:** developer.agent  
**Task:** Run the full test suite before starting new work. If tests fail, assign investigation to tester.agent. If tests pass, proceed to work item selection.  
**Input:** Current test suite  
**Result:** Test execution status. If failures detected, tester.agent assigned to investigate and fix.  
**Next Step:** Work Item Selection.  

#### Step 2: Work Item Selection
**Agent:** developer.agent  
**Task:** The agent follows a BUG free principle and picks bugs first from backlog. If there are no bugs, the agent picks features. If there are no features the agent is done. If there are features the agent resolves dependencies between the items and picks the one with the highest priority. The agent assigns the picked work item to itself, moves it to the implementing column, updates the status in the work item document, and commits the changes to the repository. The agent then hands creates a task work item to execute the TDD workflow for the related feature and assigns it to the tester.agent.   
**Input:** Backlog of work items (BUGs and FEATUREs)  
**Result:** Work item document updated with new status and assignment, and changes committed to the repository. And handoff of TDD related task to tester.agent for TDD workflow execution.  
**Next Step:** TDD Workflow Execution.

#### Step 3: TDD Workflow Execution
**Agent:** tester.agent 
**Task:** The agent picks the TDD task. And initiates the TDD workflow for the related feature. The agent implements tests for the feature. Ensures that the tests fail. Then the agent moves the TDD task to done column, updates the status in the work item document, and commits the changes to the repository. The agent then handoffs the implementation of the feature to developer.agent.
**Input:** TDD task work item
**Result:** Tests implemented for the feature, TDD task marked as done, and handoff of implementation to developer.agent.
**Next Step:** Implementation of the feature.

#### Step 4: Implementation of the feature
**Agent:** developer.agent  
**Task:** The agent implement the feature. The agent ensures that all tests related to the feature pass. Then the agent moves the work item to done column, updates the status in the work item document, and commits the changes to the repository.  
**Input:** Assigned feature work item  
**Result:** Feature implemented, all tests passed, and work item marked as done.  
**Next Step:** Assessment of work results by Tester.

#### Step 5: Assessment of work results by Tester
**Agent:** tester.agent  
**Task:** The agent assesses the results of the implemented feature. The agent verifies that all tests pass and that the feature meets the specified requirements. If the feature does not meet the requirements or if any tests fail, the agent creates a bug work item in the backlog and assigns it to developer.agent for fixing. If the feature meets the requirements and all tests pass, the agent updates the status of the feature work item to done and commits the changes to the repository.  
**Input:** Completed feature work item  
**Result:** Test report, work item status updated, and changes committed to the repository.  
**Next Step:** Assessment of work results by Architect.  

#### Step 6: Assessment of work results by Architect
**Agent:** architect.agent  
**Task:** The agent assesses the results of the implemented feature from an architectural perspective. The agent verifies that the implementation aligns with the defined architecture and design principles. If the implementation does not align with the architecture, the agent creates a technical debt record (DEBTR) work item in the backlog and assigns it to developer.agent for remediation. If the implementation aligns with the architecture, the agent updates the status of the feature work item and commits changes to the repository.  
**Input:** Completed feature work item, source code, and architecture vision documents.  
**Result:** Architectural assessment completed, assessment result documented in work item, status updated, and changes committed to the repository.  
**Next Step:** Assessment of work results by Security Agent.

#### Step 7: Assessment of work results by Security Agent
**Agent:** security.agent  
**Task:** The security agent assesses the results of the implemented feature from a security perspective. The agent verifies that the implementation does not introduce any security vulnerabilities and adheres to security best practices. If any security issues are identified, the agent creates a bug work item in the backlog and assigns it to developer.agent for fixing. If the implementation meets security standards, the agent updates the status of the feature work item and commits changes to the repository.  
**Input:** Completed feature work item, source code, and security guidelines documents.   
**Result:** Security assessment completed, assessment result documented in work item, status updated, and changes committed to the repository.  
**Next Step:** License Governance Assessment.

#### Step 8: License Governance Assessment
**Agent:** license.agent  
**Task:** Review code changes, dependencies, and assets for license compatibility and attribution requirements. Document findings and remediation steps in the work item. Hand back to developer.agent with pass/review/fail status.  
**Input:** Completed feature work item, source code, dependency list, third-party assets.  
**Result:** License compliance status documented in work item, required attributions verified, status updated, and changes committed to the repository.  
**Next Step:** Documentation Assessment.

#### Step 9: Documentation Assessment
**Agent:** documentation.agent  
**Task:** Verify that README.md and user documentation reflect the implemented changes. Update documentation if needed. Document changes in the work item.  
**Input:** Completed feature work item, current README.md, recent changes summary.  
**Result:** Documentation updated if needed, assessment documented in work item, status updated, and changes committed to the repository.  
**Next Step:** Work Item Selection (return to Step 2).