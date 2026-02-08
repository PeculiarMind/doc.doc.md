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

#### Damage Factor and CIA Classification

The **Damage** factor MUST consider the CIA classification of affected data/assets. Use this guidance:

| CIA Classification | Base Damage Range | Assessment Guidance |
|-------------------|-------------------|---------------------|
| **Highly Confidential** (Critical C/I/A) | 8-10 | Compromise causes critical impact: credential exposure, key material loss, complete system compromise |
| **Confidential** (High C/I/A) | 6-8 | Compromise causes significant impact: PII exposure, proprietary data loss, privilege escalation |
| **Internal** (Medium C/I/A) | 3-6 | Compromise causes moderate impact: configuration exposure, internal process disruption |
| **Public** (Low C/I/A) | 0-3 | Compromise causes minimal impact: public information disclosure, non-critical service degradation |

**Example**: A threat targeting authentication credentials (Highly Confidential/Critical) that could compromise the entire system would score Damage=10. The same attack vector against public documentation (Public/Low) would score Damage=1-2.

### Likelihood Calculation

DREAD Likelihood is the average of all five factors:

```
DREAD Likelihood = (Damage + Reproducibility + Exploitability + Affected Users + Discoverability) / 5
```

Result: 0-10 scale representing probability of exploitation.

## Risk Rating Calculation

### Formula

Risk combines DREAD likelihood with STRIDE impact, weighted by CIA classification to reflect attacker motivation:

```
Risk Rating = DREAD Likelihood × STRIDE Impact × CIA Weight Factor
```

**Scale**: 0-400 per STRIDE category (CIA weight ranges from 1x to 4x)

### CIA Weight Factor

CIA classification acts as a risk multiplier, reflecting that high-value assets are more attractive attack targets:

| CIA Classification | Weight Factor | Rationale |
|--------------------|---------------|------------|
| **Highly Confidential** | 4 | Critical assets; prime targets for sophisticated attackers; maximum attacker motivation |
| **Confidential** | 3 | High-value assets; attractive to most threat actors; significant attacker interest |
| **Internal** | 2 | Moderate-value assets; opportunistic target; moderate attacker motivation |
| **Public** | 1 | Baseline; even public assets carry inherent risk; weight does not reduce below DREAD assessment |

**Rationale**: Attackers prioritize targets based on asset value. A vulnerability in Highly Confidential data is intrinsically more dangerous than the same vulnerability in Public data, both due to impact (captured in Damage factor) and attacker motivation (captured in CIA weight). The weight factor starts at 1 (not below) to ensure CIA classification only amplifies risk, never artificially reduces it.

### Rating Scale

| Risk Score | Severity | Response |
|------------|----------|----------|
| 250-400 | **Critical** | Immediate mitigation required; blocks release |
| 150-249 | **High** | Mitigation required before release |
| 75-149 | **Medium** | Mitigation recommended; document acceptance if deferred |
| 25-74 | **Low** | Track for future improvement |
| 0-24 | **Informational** | Consider for defense in depth |

**Note**: The scale (0-400) reflects CIA weight amplification up to 4x for Highly Confidential assets, with Public assets maintaining baseline DREAD×STRIDE scores.

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

**Risk Integration**: CIA classification directly determines the DREAD Damage factor baseline. See [Damage Factor and CIA Classification](#damage-factor-and-cia-classification) for assessment guidance.

## Risk Assessment Approach

Security assessment follows this workflow:

1. **Define Scope**: Identify components, interfaces, data flows, and protocols
2. **Classify Data**: Apply CIA triad to all data processed and exchanged (Highly Confidential/Confidential/Internal/Public)
3. **Threat Modeling**: Enumerate threats using STRIDE categories for each component and data flow
4. **Likelihood Assessment**: Calculate DREAD likelihood for each threat
   - **Critical**: Assess Damage factor using CIA classification of affected assets (see Damage Factor guidance)
   - Assess remaining DREAD factors (Reproducibility, Exploitability, Affected Users, Discoverability)
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

Each security scope in [02_scopes/](../02_scopes/) applies this methodology to specific system domains.
