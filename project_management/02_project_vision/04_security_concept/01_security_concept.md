# Security Concept

## Table of Contents

- [1. Introduction](#1-introduction)
  - [1.1 Purpose](#11-purpose)
  - [1.2 Scope](#12-scope)
  - [1.3 Overview of Security Analysis Methods](#13-overview-of-security-analysis-methods)
    - [System Decomposition](#system-decomposition)
    - [CIA Triad - Classification of Assets](#cia-triad---classification-of-assets)
    - [STRIDE](#stride)
    - [DREAD](#dread)
    - [Risk Interpretation and Decision Framework](#risk-interpretation-and-decision-framework)
- [2. Asset Catalog](#2-asset-catalog)

---

## 1. Introduction

### 1.1 Purpose
This security concept document establishes the methodological framework for identifying, analyzing, and mitigating security risks throughout the ProTemp project lifecycle. It serves as the authoritative guide for conducting systematic threat modeling and security assessments.

**Primary Audiences:**
- **Security Experts and Security Agent** - Human experts and the security agent use this framework to perform security reviews and maintain security documentation
- **Developers and Developer Agent** - Apply security analysis during implementation and understand mitigation requirements
- **Architects and Architect Agent** - Incorporate security considerations into architectural decisions and design reviews
- **Testers and Tester Agent** - Derive security test cases from identified threats and validate security controls

**Application Points:**
- **Requirements Phase** - Identify security requirements from threat analysis
- **Design Reviews** - Evaluate architectural decisions against security principles
- **Implementation** - Assess code for security vulnerabilities before merge
- **Testing** - Validate security controls and threat mitigations
- **Deployment** - Verify security configuration and runtime protections

### 1.2 Scope
The scope of this security concept is defined by the information described in the project goals, the architecture vision, and the requirements. It focuses on the the projects context described in the architecture vision chapter system scope and context, its building blocks, the relations between them and the external systems. The security concept considers also the classification of the data processed by the system.

### 1.3 Overview of Security Analysis Methods
This security concept integrates four key methodologies for a comprehensive security analysis: System decomposition, STRIDE, DREAD, and the CIA Triad.

#### System Decomposition
A method to break down the system into components and smaller, analyzable scopes. 
The components and the data processed by them are classified by using the CIA triad, which helps in understanding the security requirements and potential vulnerabilities of each component. A scope covers only a few components and enables a detailed analysis of involved components their interfaces and interactions between them, to identify potential attack surfaces and vulnerabilities. To every scope a STRIDE analysis is performed to identify potential threats, and a DREAD assessment is conducted to evaluate the risk associated with those threats. 

#### CIA Triad - Classification of Assets
Assets are categorized as primary assets (typically but not limited to the data) or supporting assets (typically but not limited to the infrastructure, applications, and services) based on their importance to the system's functionality and security. Each asset is rated according to the CIA triad:
- **Confidentiality** - The degree to which information is protected from unauthorized access.
- **Integrity** - The degree to which information is protected from unauthorized modification.
- **Availability** - The degree to which information is accessible and usable upon demand by an authorized entity.

This rating indicates the protection level required for each asset and helps in prioritizing security measures.

Every class is assigned a value between 1 and 3 as follows:
| Classification | Value | Description |
|---|:---:|---|
| HIGH   | 3     | Critical asset, high impact if compromised      |
| MEDIUM | 2     | Important asset, moderate impact if compromised |
| LOW    | 1     | Non-critical asset, low impact if compromised   |

#### STRIDE
A threat modeling framework is used to determine the impact. It categorizes potential threats into six categories: 
1. **Spoofing** - pretending to be someone or something else
2. **Tampering** - unauthorized modification of data
3. **Repudiation** - denying an action or event
4. **Information Disclosure** - unauthorized access to information
5. **Denial of Service** - disrupting service availability
6. **Elevation of Privilege** - gaining unauthorized access to higher privileges

| Threat Category | Violated Property | Mitigation |
|---|---|---|
| Spoofing               | Authentication  | Strong authentication mechanisms, multi-factor authentication |
| Tampering              | Integrity       | Data validation, checksums, digital signatures                |
| Repudiation            | Non-repudiation | Logging, digital signatures, audit trails                     |
| Information Disclosure | Confidentiality | Encryption, access controls, data masking                     |
| Denial of Service      | Availability    | Redundancy, rate limiting, failover mechanisms                |
| Elevation of Privilege | Authorization   | Least privilege, access control                               |

Every threat will be rated with a value between 1 and 5, where 1 means that the threat has a none impact and 5 means that the threat has a critical impact.

| Severity | Value | Potential Impact | 
|---|:---:|---|    
| CRITICAL | 5     | all users are affected or complete system is impacted                            |  
| HIGH     | 4     | significant number of users are affected or major system components are impacted |  
| MEDIUM   | 3     | moderate number of users are affected or some system components are impacted     |  
| LOW      | 2     | minor number of users are affected or minor system components are impacted       |   
| NONE     | 1     | -                                                                                |  

STRIDE score is calculated per scope by summing up the values of all threat categories and dividing it by 6.


#### DREAD
A risk assessment model that evaluates threats based on five criteria:
1. **Damage Potential** - the potential impact of a threat if it were to be exploited 
2. **Reproducibility** - how easily a threat can be reproduced
3. **Exploitability** - how easily a threat can be exploited
4. **Affected Users** - the number of users that would be affected by the threat
5. **Discoverability** - how easily a threat can be discovered

**DREAD Rating Guidelines by Criteria**:

Each DREAD criterion is rated on a scale of 1-5. Use the guidance below to assign values:

| Rating | Damage Potential | Reproducibility | Exploitability | Affected Users | Discoverability |
|:------:|------------------|-----------------|----------------|----------------|-----------------|
| **5 - CRITICAL** | Complete data loss, system compromise, or catastrophic business impact | 100% reproducible; occurs every time | No special skills or tools required; fully automated exploit available | All users affected; system-wide impact | Publicly known; widely documented; obvious to any observer |
| **4 - HIGH** | Major data breach, significant DoS, or severe functionality loss | Highly reproducible (>75% success rate) | Basic skills required; known exploits or readily available tools | Majority of users (>50%); major subsystems affected | Easy to discover with common scanning tools or basic reconnaissance |
| **3 - MEDIUM** | Moderate data exposure, partial service degradation, or noticeable impact | Moderately reproducible (~50% success rate); some conditions must be met | Moderate skill required; some specialized knowledge or custom tools needed | Significant portion of users (25-50%); subset of features affected | Requires focused investigation or moderate technical knowledge to find |
| **2 - LOW** | Limited information leak, minor inconvenience, or isolated impact | Difficult to reproduce (<25% success rate); specific conditions required | Advanced skills required; deep technical knowledge or sophisticated tools | Small group of users (<25%); limited scope or edge cases only | Obscure; requires insider knowledge or specific configurations to discover |
| **1 - NEGLIGIBLE** | Minimal to no real impact; theoretical concern only | Nearly impossible to reproduce; extremely rare conditions | Theoretical only; requires source code access or highly unlikely circumstances | Single user or isolated instance; virtually no practical impact | Requires source code audit or extensive reverse engineering to discover |

**DREAD Scoring Process**:

1. Rate each of the five criteria individually using the table above
2. Sum the five criterion values
3. Divide by 5 to get the DREAD score (result will be 1.0 to 5.0)

**Example**:
```
Threat: SQL Injection in search parameter
- Damage Potential: 5 (complete database access)
- Reproducibility: 5 (works every time)
- Exploitability: 3 (requires SQL knowledge)
- Affected Users: 4 (all users' data at risk)
- Discoverability: 4 (common vulnerability, easy to find)

DREAD Score = (5 + 5 + 3 + 4 + 4) / 5 = 4.2 (HIGH risk)
```


#### Risk Interpretation and Decision Framework

After calculating STRIDE and DREAD scores for a security scope, the overall risk level is determined by combining both assessments. This combined score guides the required security response.

**Risk Calculation**:
```
Combined Risk Score = (STRIDE Score + DREAD Score) / 2
```

**Risk Level Matrix**:

| Score Range | Risk Level | Action Required | Deployment Impact |
|-------------|------------|-----------------|-------------------|
| 4.5 - 5.0   | CRITICAL   | Immediate mitigation required; severe vulnerabilities must be fixed | **BLOCKS** deployment until resolved |
| 3.5 - 4.4   | HIGH       | Mitigation required; security controls must be implemented | **BLOCKS** release; must be fixed before deployment |
| 2.5 - 3.4   | MEDIUM     | Mitigation recommended; acceptable with documented risk acceptance | Deployable with written justification and acceptance by project lead |
| 1.5 - 2.4   | LOW        | Consider mitigation; monitor for changes in threat landscape | Acceptable; track in security monitoring |
| 1.0 - 1.4   | NEGLIGIBLE | Document findings; maintain awareness | Acceptable; periodic review |

**Risk Response Guidelines**:
- **CRITICAL/HIGH**: Security agent/expert creates bug work items assigned to developer; work item blocked until mitigations implemented and verified
- **MEDIUM**: Security agent/expert documents risk in SECREV report; project lead approves risk acceptance or mitigation plan
- **LOW/NEGLIGIBLE**: Security agent/expert documents in SECREV report for awareness; no immediate action required but findings remain on record

**Risk Acceptance Process**:
For MEDIUM-level risks that will not be immediately mitigated:
1. Security agent/expert documents threat, impact, and recommended mitigation in SECREV report
2. Project lead reviews and provides written acceptance with justification
3. Accepted risk is tracked in security concept and reviewed quarterly
4. Deployment proceeds with documented acceptance

---

## 2. Asset Catalog

A centralized catalog of all project assets with CIA ratings is maintained in:

**Location**: `project_management/02_project_vision/04_security_concept/02_asset_catalog.md`

**Purpose**: The asset catalog serves as a foundational reference for:
- System decomposition and threat modeling
- Identifying which assets require protection
- Prioritizing security measures based on CIA ratings
- Tracking asset inventory across security analyses

**Usage**: When performing security analysis using the Security Analysis Scope (SAS) template, reference and update the asset catalog to ensure consistent asset classification across the project.

**Maintenance**: The asset catalog should be updated when:
- New components or data stores are added to the system
- Asset sensitivity changes (e.g., new regulations, business impact changes)
- Security incidents reveal previously unidentified assets
- Architecture changes affect asset boundaries or ownership

