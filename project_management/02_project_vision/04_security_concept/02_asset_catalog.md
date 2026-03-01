## Asset Catalog

This section catalogs all assets of this project, categorizing them by type and assessing their confidentiality, integrity, and availability (CIA) ratings. This catalog serves as a foundational reference for subsequent threat modeling and risk assessment activities.

**Asset ID**: A unique identifier for each asset, following a consistent naming convention (e.g., ASSET-{{FOUR_DIGIT_NUMBER}}).  
**Asset Name**: A descriptive name for the asset that clearly indicates its purpose or function.  
**Asset Category**: PRIMARY or SUPPORTING, indicating whether the asset is a primary focus of the project or a supporting element.  
**Type**: The category of the asset (e.g., Data, System, Network, Application, etc.).  
**Description**: A brief explanation of the asset, including its role in the system and any relevant details.  
**C (Confidentiality)**: A rating of the asset's confidentiality requirement, typically on a scale of 1 (Low) to 3 (High).  
**I (Integrity)**: A rating of the asset's integrity requirement, typically on a scale of 1 (Low) to 3 (High).  
**A (Availability)**: A rating of the asset's availability requirement, typically on a scale of 1 (Low) to 3 (High). 

| Asset ID | Asset Name | Asset Category | Type | Description | C | I | A |
|----------|------------|----------------|------------|-------------|:-:|:-:|:-:|
| **PRIMARY ASSETS (Data)** |
| ASSET-0001 | User Documents | PRIMARY | Data | Original documents from input directory processed by the system. May contain sensitive personal/business data. | 3 | 3 | 3 |
| ASSET-0002 | Generated Markdown Files | PRIMARY | Data | Output markdown files with document metadata and summaries. Inherits sensitivity from source documents. | 3 | 3 | 2 |
| ASSET-0003 | Document Metadata | PRIMARY | Data | File attributes, permissions, ownership, MIME types extracted during processing. May reveal sensitive information about file origins. | 2 | 3 | 2 |
| ASSET-0004 | File System Paths | PRIMARY | Data | Input/output directory paths and file locations. May reveal system structure and user directory layouts. | 2 | 2 | 2 |
| **SUPPORTING ASSETS (Infrastructure)** |
| ASSET-0101 | doc.doc.sh CLI | SUPPORTING | Application | Main bash script providing CLI interface and orchestration. Core entry point for all operations. | 1 | 3 | 3 |
| ASSET-0102 | Python Filter Engine | SUPPORTING | Application | filter.py implementing complex include/exclude filtering logic. Critical for correct file selection. | 1 | 3 | 3 |
| ASSET-0103 | Bash Component Scripts | SUPPORTING | Application | help.sh, logging.sh, plugins.sh, templates.sh providing core functionality. | 1 | 3 | 3 |
| ASSET-0104 | Plugin System | SUPPORTING | Application | Plugin discovery, validation, dependency resolution, and execution framework. | 1 | 3 | 3 |
| ASSET-0105 | Plugin Descriptors | SUPPORTING | Configuration | JSON descriptor files defining plugin metadata, interfaces, and dependencies. Invalid descriptors can cause malfunction. | 1 | 3 | 2 |
| ASSET-0106 | Plugin Executables | SUPPORTING | Application | Plugin main.sh, install.sh, installed.sh scripts. Untrusted plugins pose execution risk. | 2 | 3 | 3 |
| ASSET-0107 | Template Files | SUPPORTING | Configuration | Markdown templates with variable placeholders. Template injection risk if not sanitized. | 1 | 3 | 2 |
| ASSET-0108 | System Utilities | SUPPORTING | Infrastructure | External tools (find, file, stat, grep, etc.) relied upon by core and plugins. Availability critical. | 1 | 2 | 3 |
| ASSET-0109 | Python Runtime | SUPPORTING | Infrastructure | Python 3.12+ interpreter required for filter engine. Vulnerability in Python affects system. | 1 | 2 | 3 |
| ASSET-0110 | Bash Shell | SUPPORTING | Infrastructure | Bash 4.0+ shell environment. Shell vulnerabilities can affect execution. | 1 | 2 | 3 |
| **SUPPORTING ASSETS (Configuration & State)** |
| ASSET-0201 | Plugin Activation State | SUPPORTING | Configuration | Tracking which plugins are active/inactive. Incorrect state can lead to unexpected behavior. | 1 | 2 | 2 |
| ASSET-0202 | User Configuration | SUPPORTING | Configuration | Future: User preferences, default templates, excluded paths. May contain sensitive defaults. | 2 | 2 | 2 |
| ASSET-0203 | Installation Paths | SUPPORTING | Configuration | System-wide (/usr/local) or user-local installation paths. Path confusion can cause privilege issues. | 1 | 2 | 2 |
| ASSET-0204 | Log Files | SUPPORTING | Data | Error logs, processing logs, debug output. May inadvertently contain sensitive file content or paths. | 2 | 2 | 1 |
| ASSET-0205 | Environment Variables | SUPPORTING | Configuration | FILE_PATH, OUTPUT_DIR, PLUGIN_DATA_DIR passed to plugins. Injection vector if not sanitized. | 1 | 3 | 3 |
| **SUPPORTING ASSETS (Access)** |
| ASSET-0301 | File System Permissions | SUPPORTING | Access Control | Read access to input directory, write access to output directory, execute access to plugins. | 1 | 3 | 3 |
| ASSET-0302 | User Execution Context | SUPPORTING | Access Control | Unix user context running doc.doc.sh. Determines accessible files and system resources. | 1 | 3 | 3 |
| ASSET-0303 | Plugin Data Directory | SUPPORTING | Infrastructure | Temporary directory for plugin-specific data during processing. May contain intermediate sensitive data. | 2 | 2 | 2 |

