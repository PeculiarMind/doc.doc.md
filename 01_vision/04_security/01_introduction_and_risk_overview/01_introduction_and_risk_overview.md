# Security Concept: Introduction and Risk Overview

## Table of Contents

- [Introduction](#introduction)
- [STRIDE Threat Modeling](#stride-threat-modeling)
  - [Threat Categories](#threat-categories)
- [DREAD Risk Assessment](#dread-risk-assessment)
  - [Likelihood Factors](#likelihood-factors)
  - [Likelihood Calculation](#likelihood-calculation)
- [Risk Rating Calculation](#risk-rating-calculation)
  - [Formula](#formula)
  - [Rating Scale](#rating-scale)
- [CIA Triad and Data Classification](#cia-triad-and-data-classification)
  - [Classification Levels](#classification-levels)
- [Risk Assessment Approach](#risk-assessment-approach)

## Introduction

This document establishes the security methodology for doc.doc.md. The approach combines industry-standard threat modeling (STRIDE), quantitative risk assessment (DREAD), and data classification (CIA triad) to systematically identify, analyze, and mitigate security risks.

**Integrated Methodology**: CIA classification is not merely descriptive—it has dual impact on risk assessment:
1. **Damage Factor Baseline**: CIA classification determines the baseline for DREAD Damage assessment
2. **Risk Weight Multiplier**: CIA classification acts as a weight factor on final risk scores, reflecting that high-value assets are more attractive attack targets and deserve proportionally higher risk ratings

Security concept documentation is organized into:
- **Introduction and Risk Overview** (this document): Methodology and standards
- **Scopes**: Security analysis per system domain, covering components, interactions, data flows, and threat models

### Operational Context and Threat Model Boundaries

The toolkit operates in a **single-user, local-only context** as defined in [TC-0007: Single-User Operator Trust Model](../../03_architecture/02_architecture_constraints/TC_0007_single_user_operator_trust_model.md). This architectural constraint establishes critical boundaries for the security threat model:

**Operator Trust Model**:
- The **operator** (user running the toolkit) is the owner of the data being analyzed OR has explicit authorized read access to all source documents
- The operator is a **trusted entity** with respect to data access and operations
- Target environments: personal workstations, homelabs, NAS devices, SSH-accessible servers
- No multi-user scenarios with privilege separation

**Threats In Scope**:
- **External Attackers**: Remote exploitation of vulnerabilities in the toolkit
- **Malicious Input**: Crafted documents, templates, or configuration designed to exploit processing logic
- **Malicious Plugins**: Third-party code attempting to escape sandbox, access unauthorized resources, or exfiltrate data
- **Supply Chain Attacks**: Compromised dependencies, tools, or development containers
- **Data Corruption**: Malicious input causing integrity failures

**Threats Out of Scope**:
- **Malicious Operator**: Intentional misuse by the user running the toolkit
- **Information Disclosure to Operator**: Path disclosure, detailed errors, stack traces (operator already has filesystem access)
- **Privilege Escalation from Operator**: Operator already runs toolkit with their own privileges
- **Multi-User Access Control**: No lesser-privileged users exist in the operational model

**Security Control Focus**: Protecting the operator and their data from external threats and malicious input, NOT hiding information from the operator or preventing operator actions.

## STRIDE Threat Modeling

STRIDE identifies security threats across six categories, each addressing distinct attack vectors.

### Threat Categories

| Category | Definition | Impact Assessment |
|----------|------------|-------------------|
| **Spoofing** | Impersonating another entity (user, process, system) to gain unauthorized access | Loss of authentication integrity; unauthorized actions attributed to legitimate entities |
| **Tampering** | Unauthorized modification of data or code | Data corruption; system compromise; logic manipulation |
| **Repudiation** | Denying having performed an action without verifiable proof | Lack of accountability; inability to trace malicious actions |
| **Information Disclosure** | Exposure of confidential information to unauthorized parties | Privacy violations; credential theft; competitive disadvantage |
| **Denial of Service** | Degrading or disrupting system availability | Service interruption; resource exhaustion; user impact |
| **Elevation of Privilege** | Gaining higher access rights than authorized | Complete system compromise; privilege abuse; lateral movement |

**Impact Ratings**: Each STRIDE category is assessed on a scale of 0-10 based on potential damage to the system, users, and data.

## DREAD Risk Assessment

DREAD quantifies the likelihood of threat exploitation through five factors.

### Likelihood Factors

| Factor | Definition | Rating Scale (0-10) |
|--------|------------|---------------------|
| **Damage** | Potential harm if vulnerability is exploited (weighted by CIA classification) | 0=None, 5=Individual user, 10=Complete system compromise |
| **Reproducibility** | Ease of reproducing the attack | 0=Nearly impossible, 5=Difficult, 10=Trivial |
| **Exploitability** | Skill and resources required to exploit | 0=Advanced skills/tools, 5=Skilled attacker, 10=No skills required |
| **Affected Users** | Proportion of users impacted | 0=None, 5=Some users, 10=All users |
| **Discoverability** | Ease of finding the vulnerability | 0=Nearly impossible, 5=Difficult, 10=Obvious |

### Likelihood Calculation

DREAD Likelihood is the average of all five factors:

```
DREAD Likelihood = (Damage + Reproducibility + Exploitability + Affected Users + Discoverability) / 5
```

Result: 0-10 scale representing probability of exploitation.

### CIA Weight Factor

CIA classification acts as a risk multiplier, reflecting that high-value assets are more attractive attack targets:

| CIA Classification | Weight Factor | Rationale |
|--------------------|---------------|------------|
| **Highly Confidential** | 4 | Critical assets; prime targets for sophisticated attackers; maximum attacker motivation |
| **Confidential** | 3 | High-value assets; attractive to most threat actors; significant attacker interest |
| **Internal** | 2 | Moderate-value assets; opportunistic target; moderate attacker motivation |
| **Public** | 1 | Baseline; even public assets carry inherent risk; weight does not reduce below DREAD assessment |

**Rationale**: Attackers prioritize targets based on asset value. A vulnerability in Highly Confidential data is intrinsically more dangerous than the same vulnerability in Public data, both due to impact (captured in Damage factor) and attacker motivation (captured in CIA weight). The weight factor starts at 1 (not below) to ensure CIA classification only amplifies risk, never artificially reduces it.


## Risk Rating Calculation

### Formula

Risk combines DREAD likelihood with STRIDE impact and CIA classification to reflect attacker motivation:

```
Risk Rating = DREAD Likelihood × STRIDE Impact × CIA Weight Factor
Where:
- DREAD Likelihood = (Damage + Reproducibility + Exploitability + Affected Users + Discoverability) / 5
- STRIDE Impact = 0-10 rating for threat category
- CIA Weight Factor = 1x to 4x based on asset classification
- Maximum: 10 × 10 × 4 = 400```

### Rating Scale

| Risk Score | Severity | Response |
|------------|----------|----------|
| 250-400 | **Critical** | Immediate mitigation required; blocks release |
| 150-249 | **High** | Mitigation required before release |
| 75-149 | **Medium** | Mitigation recommended; document acceptance if deferred |
| 25-74 | **Low** | Track for future improvement |
| 0-24 | **Informational** | Consider for defense in depth |

**Note**: The scale (0-400) reflects CIA weight amplification up to 4x for Highly Confidential assets, with Public assets maintaining baseline DREAD×STRIDE scores.

### Example: CIA Weight Impact on Same Threat

This table demonstrates how the same vulnerability receives different risk ratings based on asset classification:

| Scenario | CIA Classification | DREAD Likelihood | STRIDE Impact | CIA Weight | Risk Score | Severity |
|----------|-------------------|------------------|---------------|------------|------------|----------|
| Command injection in SSH key management | Highly Confidential | 8.0 | 10 (Tampering) | 4x | **320** | Critical |
| Command injection in user config parser | Confidential | 7.0 | 10 (Tampering) | 3x | **210** | High |
| Command injection in temp file handler | Internal | 6.0 | 10 (Tampering) | 2x | **120** | Medium |
| Command injection in help text renderer | Public | 5.0 | 10 (Tampering) | 1x | **50** | Low |

**Interpretation**: The same attack vector (command injection with STRIDE Tampering=10) results in vastly different risk ratings based on the value and criticality of the affected asset. This reflects both the actual damage potential (captured in DREAD Likelihood) and attacker motivation (captured in CIA Weight).

## CIA Triad and Data Classification

The CIA triad defines security properties for data protection:

- **Confidentiality**: Restrict access to authorized parties only
- **Integrity**: Ensure data accuracy and prevent unauthorized modification
- **Availability**: Maintain reliable access to data and systems

### Classification Levels

Data is classified based on impact if compromised:

| Classification | Confidentiality | Integrity | Availability | Examples |
|----------------|-----------------|-----------|--------------|----------|
| **Highly Confidential** | Critical | Critical | Critical | Authentication credentials, cryptographic keys |
| **Confidential** | High | High | High | User personal data, proprietary code |
| **Internal** | Medium | Medium | Medium | Configuration files, internal documentation |
| **Public** | Low | Variable | Low | Public documentation, help text |

Each data element is assigned a CIA classification to determine appropriate security controls.

## Risk Assessment Approach

Security assessment follows this workflow:

1. **Define Scope**: Identify components, interfaces, data flows, and protocols
2. **Classify Data**: Apply CIA triad to all data processed and exchanged (Highly Confidential/Confidential/Internal/Public)
3. **Threat Modeling**: Enumerate threats using STRIDE categories for each component and data flow
4. **Likelihood Assessment**: Calculate DREAD likelihood for each threat
   - Calculate DREAD Likelihood average
5. **Impact Assessment**: Determine STRIDE impact ratings for each relevant category
6. **Risk Calculation**: Compute risk ratings (DREAD × STRIDE × CIA Weight) for each threat-category combination
7. **Mitigation Strategy**: Define controls proportional to risk ratings and CIA classification
8. **Residual Risk**: Document accepted risks after mitigation
9. **Validation**: Verify controls through testing and review
10. **Maintenance**: Update threat models as architecture evolves

**Key Integration Points**: 
- **Damage Assessment**: CIA classification determines baseline Damage scores (Highly Confidential=8-10, Confidential=6-8, Internal=3-6, Public=0-3)
- **Risk Weighting**: CIA classification multiplies final risk scores to reflect attacker motivation (Highly Confidential=4x, Confidential=3x, Internal=2x, Public=1x baseline)

This dual approach ensures that threats to critical assets receive appropriately elevated risk ratings from both impact and attractiveness perspectives. The weight factor starts at 1 to ensure CIA never artificially reduces risk below the DREAD×STRIDE assessment.

## Worked Example: Complete Threat Assessment

This example demonstrates the complete risk assessment workflow for a real threat.

### Scenario: Command Injection in Plugin Path Loading

**Context**: The doc.doc.sh script accepts plugin paths via command-line arguments and executes code from those paths. An attacker could provide a malicious path containing shell metacharacters.

#### Step 1: Define Scope
- **Component**: Plugin loading subsystem in doc.doc.sh
- **Interface**: Command-line argument parsing (`--plugin` flag)
- **Data Flow**: User input → argument parser → shell execution

#### Step 2: Classify Data
- **Affected Asset**: Shell execution environment (ability to run arbitrary commands with script privileges)
- **CIA Classification**: **Highly Confidential**
  - **Confidentiality**: Critical (could expose system credentials, SSH keys)
  - **Integrity**: Critical (could modify any file accessible to user)
  - **Availability**: Critical (could crash system or delete critical files)

#### Step 3: Threat Modeling (STRIDE)
Relevant STRIDE categories for this threat:
- **Tampering**: ✓ Attacker can execute arbitrary code, modifying system state
- **Elevation of Privilege**: ✓ Could escalate to root if script runs with sudo
- **Information Disclosure**: ✓ Could exfiltrate sensitive files
- **Denial of Service**: ✓ Could crash the script or consume resources

#### Step 4: DREAD Likelihood Assessment
- **Damage**: 9/10
  - Asset is Highly Confidential (score range 8-10)
  - Complete system compromise possible
  - Could access SSH keys, credentials, private data
  
- **Reproducibility**: 9/10
  - Attack is 100% reproducible with crafted input
  - No randomization or timing dependencies
  
- **Exploitability**: 6/10
  - Requires knowledge of shell metacharacters
  - Requires local access or ability to influence arguments
  - No specialized tools needed
  
- **Affected Users**: 10/10
  - All users of the script are vulnerable
  - No user-specific conditions required
  
- **Discoverability**: 7/10
  - Obvious to security researchers examining shell script
  - May not be obvious to casual users
  - Basic penetration testing would reveal this

**DREAD Likelihood**: (9 + 9 + 6 + 10 + 7) / 5 = **8.2**

#### Step 5: STRIDE Impact Assessment
For each relevant STRIDE category, assess impact (0-10):

- **Tampering**: 10/10 (complete code execution, can modify anything)
- **Elevation of Privilege**: 8/10 (could escalate if script runs privileged)
- **Information Disclosure**: 9/10 (full file system access)
- **Denial of Service**: 7/10 (can crash script or waste resources)

#### Step 6: Risk Calculation

For each STRIDE category:

| STRIDE Category | Impact | DREAD Likelihood | Base Risk | CIA Weight | **Final Risk** | Severity |
|----------------|--------|------------------|-----------|------------|----------------|----------|
| Tampering | 10 | 8.2 | 82 | 4x | **328** | **Critical** |
| Elevation of Privilege | 8 | 8.2 | 65.6 | 4x | **262** | **Critical** |
| Information Disclosure | 9 | 8.2 | 73.8 | 4x | **295** | **Critical** |
| Denial of Service | 7 | 8.2 | 57.4 | 4x | **230** | **High** |

**Highest Risk**: **328** (Tampering) - **CRITICAL**

#### Step 7: Mitigation Strategy

Given critical risk rating:

1. **Input Validation** (Primary Control):
   - Whitelist allowed characters in plugin paths
   - Reject paths containing shell metacharacters: `;`, `|`, `&`, `$`, `` ` ``, `(`, `)`, `<`, `>`
   - Validate against expected path patterns

2. **Path Sanitization** (Defense in Depth):
   - Use `realpath` to resolve canonical path
   - Verify plugin file exists and is readable
   - Check plugin directory is within expected location

3. **Secure Execution** (Defense in Depth):
   - Use array-based command execution instead of string interpolation
   - Avoid `eval` and `source` with user-controlled paths
   - Quote all variables in shell expansions

4. **Testing** (Validation):
   - Write unit tests with malicious path inputs
   - Include fuzzing test cases
   - Test cases: `--plugin "; rm -rf /"`, `--plugin "$(whoami)"`, etc.

#### Step 8: Residual Risk

After implementing mitigations:
- Input validation reduces **Exploitability** from 6 → 2 (requires bypass)
- New DREAD Likelihood: (9 + 9 + 2 + 10 + 7) / 5 = **7.4**
- New Tampering Risk: 7.4 × 10 × 4 = **296** (still Critical)

Further mitigation needed:
- Implement strict plugin directory whitelist
- Reduces **Affected Users** from 10 → 3 (only users with write access to plugin dirs)
- Reduces **Damage** from 9 → 7 (limited to plugin directory scope)
- Final DREAD: (7 + 9 + 2 + 3 + 7) / 5 = **5.6**
- Final Risk: 5.6 × 10 × 4 = **224** (High - acceptable with documentation)

#### Step 9: Validation
- Unit tests verify input rejection
- Integration tests verify secure plugin loading
- Manual penetration testing confirms no bypass

#### Step 10: Documentation
- Document accepted residual risk (224 - High)
- Require plugin directory to be user-owned only
- Add security warning to README

---

Each security scope in `01_vision/04_security/02_scopes/` applies this methodology to specific system domains.
