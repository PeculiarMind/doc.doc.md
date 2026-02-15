# Feature: Bogofilter Multi-Category Text Classification Plugin

**ID**: feature_0051_bogofilter_plugin  
**Status**: Backlog  
**Created**: 2026-02-14  
**Last Updated**: 2026-02-14

## Overview
Implement a bogofilter plugin that classifies text files into user-defined categories using Bayesian classification with multiple trained databases, enabling custom text categorization beyond spam detection.

## Description
This feature adds a new plugin that integrates bogofilter, a fast and lightweight Bayesian text classifier, into the document analysis toolkit. While bogofilter is commonly known for spam filtering, it is a general-purpose Bayesian classifier that can be trained for any text categorization task. The plugin supports multiple trained categories simultaneously, allowing users to classify documents across different dimensions.

**Implementation Components**:
- Plugin descriptor (`scripts/plugins/ubuntu/bogofilter/descriptor.json`) declaring data dependencies and outputs
- Plugin configuration file or descriptor extension to specify trained categories and database paths
- Plugin wrapper script (`scripts/plugins/ubuntu/bogofilter/bogofilter_wrapper.sh`) to invoke bogofilter for each category and parse results
- Installation script (`scripts/plugins/ubuntu/bogofilter/install.sh`) for bogofilter package
- Plugin consumes: file content or file path
- Plugin provides: classification results per category with probability scores

**Multi-Category Classification**:
- Support multiple bogofilter databases, each trained for a different category/task
- Configuration specifies category names and corresponding database paths
- Examples: `technical` (technical vs general content), `legal` (legal vs business), `quality` (high vs low quality)
- Each category classification includes: category_name, classification (positive/negative/unsure), probability (0.0-1.0)
- Plugin loops through all configured categories and evaluates the input text against each

**Bogofilter Integration**:
- Use `bogofilter -v -d <database_path>` to classify against specific trained database
- Parse bogofilter output to extract classification and confidence metrics
- Handle cases where bogofilter database is untrained or missing
- Support multiple file types via stdin or file input
- Provide clear error messages for database/configuration issues

**Plugin Behavior**:
- Process text/plain, message/rfc822, text/html MIME types
- Skip binary files automatically
- Evaluate input against all configured categories
- Return structured output: array of {category, classification, probability} objects
- Log warnings when bogofilter database lacks training data
- Support default spam/ham category plus custom user-defined categories
- Integrate seamlessly into plugin execution pipeline

## Traceability
- **Primary**: [req_0075](../../01_vision/02_requirements/01_funnel/req_0075_bogofilter_spam_analysis_plugin.md) - Bogofilter Multi-Category Text Classification Plugin
- **Related**: [req_0022](../../01_vision/02_requirements/03_accepted/req_0022_plugin_based_extensibility.md) - Plugin-based Extensibility
- **Related**: [req_0043](../../01_vision/02_requirements/03_accepted/req_0043_plugin_file_type_filtering.md) - Plugin File Type Filtering
- **Related**: [req_0007](../../01_vision/02_requirements/03_accepted/req_0007_tool_availability_verification.md) - Tool Availability Verification
- **Architecture**: [Concept 08_0001](../../01_vision/03_architecture/08_concepts/08_0001_plugin_concept.md) - Plugin Concept

## Acceptance Criteria

### Plugin Structure
- [ ] Plugin descriptor at `scripts/plugins/ubuntu/bogofilter/descriptor.json` created
- [ ] Plugin wrapper script at `scripts/plugins/ubuntu/bogofilter/bogofilter_wrapper.sh` created
- [ ] Installation script at `scripts/plugins/ubuntu/bogofilter/install.sh` created
- [ ] Plugin follows standard directory structure

### Plugin Descriptor
- [ ] Descriptor declares `name: "bogofilter"`
- [ ] Descriptor includes clear description of multi-category text classification capability
- [ ] Descriptor sets `processes.mime_types` to ["text/plain", "message/rfc822", "text/html"]
- [ ] Descriptor declares `consumes` for file_path_absolute or file_content
- [ ] Descriptor declares `provides` for classification results (category arrays with classifications and probabilities)
- [ ] Descriptor or config file specifies trained categories and database paths
- [ ] Descriptor includes proper `commandline` invocation template
- [ ] Descriptor includes `check_commandline` to verify bogofilter availability
- [ ] Descriptor includes `install_commandline` for apt-based installation

### Plugin Functionality
- [ ] Plugin reads category configuration (category names and database paths)
- [ ] Plugin invokes bogofilter for each configured category with appropriate flags (-v -d <database_path>)
- [ ] Plugin parses bogofilter classification output correctly for each category
- [ ] Plugin extracts probability scores from bogofilter output
- [ ] Plugin returns structured output: array of category classification results
- [ ] Each result includes: category_name, classification (positive/negative/unsure), probability (0.0-1.0)
- [ ] Plugin handles missing or untrained bogofilter database gracefully per category
- [ ] Plugin provides clear error messages identifying which category/database failed
- [ ] Plugin logs warnings when classification confidence is low
- [ ] Plugin handles errors (missing file, bogofilter failure, missing database) appropriately
- [ ] Plugin continues processing other categories if one category fails
- [ ] Plugin supports default categories (e.g., spam/ham) plus custom user categories

### Installation & Tool Verification
- [ ] Installation script installs bogofilter package via apt
- [ ] Check commandline verifies bogofilter is available
- [ ] Plugin prompts user to install bogofilter if missing
- [ ] Installation script handles package manager errors
- [ ] Plugin validates bogofilter version compatibility

### Integration & Testing
- [ ] Plugin integrates with plugin discovery mechanism
- [ ] Plugin executes as part of data-driven pipeline
- [ ] Plugin respects file type filtering (only processes declared MIME types)
- [ ] Plugin output serializes correctly to JSON workspace format
- [ ] Plugin tested with multiple trained categories simultaneously
- [ ] Plugin tested with custom category definitions (technical/general, legal/business, etc.)
- [ ] Plugin tested with spam/ham classification as one category
- [ ] Plugin tested with untrained bogofilter databases
- [ ] Plugin tested with missing database files
- [ ] Plugin tested with various file encodings
- [ ] Plugin tested with partial category failures (some databases missing)
- [ ] Multi-category output validated for correctness

### Documentation
- [ ] Plugin usage documented in README or plugin documentation
- [ ] Multi-category classification concept explained
- [ ] Category configuration format documented (category names, database paths)
- [ ] Bogofilter training workflow documented for each category
- [ ] Training commands documented: `bogofilter -s -d <db>` (positive), `bogofilter -n -d <db>` (negative)
- [ ] Output format documented (array of category results with classifications and probabilities)
- [ ] Example use cases provided (topic classification, quality assessment, spam filtering)
- [ ] Example category configurations provided (technical/general, legal/business, high-quality/low-quality)
- [ ] Training data requirements documented (minimum number of examples per category)
- [ ] Known limitations documented (requires training data per category, binary classification per database)

## Dependencies
- Plugin architecture (req_0022) - DONE
- Plugin file type filtering (feature_0044) - IN BACKLOG
- Plugin descriptor validation (req_0047) - DONE
- Tool installation verification (req_0007, req_0008) - DONE
- Plugin command execution (feature_0052) - IN BACKLOG (for training commands)

## Technical Notes

### Bogofilter Command Example
```bash
# Verbose classification with probability for specific database
bogofilter -v -d /path/to/category_database < input_file.txt

# Expected output format:
# X-Bogosity: Spam, spamicity=0.999999
# X-Bogosity: Ham, spamicity=0.000001
# X-Bogosity: Unsure, spamicity=0.500000
```

### Training Workflow Example
```bash
# Train "technical" category with positive examples (technical documents)
bogofilter -s -d ~/.bogofilter/technical < technical_doc1.txt
bogofilter -s -d ~/.bogofilter/technical < technical_doc2.txt

# Train with negative examples (non-technical documents)
bogofilter -n -d ~/.bogofilter/technical < general_doc1.txt
bogofilter -n -d ~/.bogofilter/technical < general_doc2.txt
```

### Plugin Configuration Example
```json
{
  "categories": [
    {
      "name": "technical",
      "database": "~/.bogofilter/technical",
      "positive_label": "technical",
      "negative_label": "general"
    },
    {
      "name": "legal",
      "database": "~/.bogofilter/legal",
      "positive_label": "legal",
      "negative_label": "business"
    },
    {
      "name": "spam",
      "database": "~/.bogofilter/spam",
      "positive_label": "spam",
      "negative_label": "ham"
    }
  ]
}
```

### Plugin Data Schema
```json
{
  "bogofilter_classifications": [
    {
      "category": "technical",
      "classification": "technical",
      "probability": 0.95,
      "label": "technical"
    },
    {
      "category": "legal",
      "classification": "business",
      "probability": 0.78,
      "label": "business"
    },
    {
      "category": "spam",
      "classification": "ham",
      "probability": 0.02,
      "label": "ham"
    }
  ]
}
```

### Training Considerations
- Each category requires separate bogofilter database with independent training
- Minimum recommended training: 100+ positive and 100+ negative examples per category
- Plugin should detect untrained database and log informative warning per category
- Consider providing example training scripts for common categories
- Plugin behavior with untrained database: return "unsure" with spamicity value and warning
- Training quality affects classification accuracy - more diverse examples yield better results

## Notes
- Created by Requirements Engineer Agent from req_0075
- Priority: Low
- Type: Feature Enhancement
- Classification: Plugin Addition
- Bogofilter is mature, stable, and widely available in Linux distributions
- Lightweight and fast, suitable for batch processing of document collections
- Multi-category support enables flexible text classification beyond spam detection
- Each bogofilter database is independent - users can mix different classification tasks
- Consider providing training helper scripts or documentation for common use cases
- Future enhancement: automatic training from labeled example directories
- **Training Interface**: Training commands best implemented via plugin command execution interface (feature_0052)
  - Example: `./doc.doc.sh -p exec bogofilter train technical --positive tech/ --negative general/`
  - Provides unified UX and avoids requiring users to interact with bogofilter directly
  - See feature_0052 for plugin command execution implementation
