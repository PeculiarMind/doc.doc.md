# Building Block View

## Level 1: Building Blocks

### Entry Script - doc.doc.sh

This is the main entry point of the doc.doc.md project. It serves as the command-line interface for the document processing tools. The script the defines different workflows and orchestrates the execution of various components based on the provided command-line arguments. It is responsible for parsing the input parameters, validating them, and coordinating the overall processing of documents.

Main workflow:
1. Parse command-line arguments
2. Validate input parameters
3. Set up logging and progress indication
4. Determine which plugins are available and active
5. Determine which plugins are installed and can be used for processing
6. Determine plugin execution order based on input and output parameters and file types => results in a ordered list of plugins to be executed for each file
7. Determine files to be processed based on input paratemeters the result will be piped into the plugin execution workflow
```bash
find <input_path> -type f -print0 | while IFS= read -r -d '' file; do
  # loop over plugins to execute and execute each plugin per "$file"
  # 
done
```

### Help System - components/help.sh

### Logging Script - components/logging.sh

### Document Processing Script - components/processing.sh

### Progress Indication Script - components/progress.sh

### Plugin Management Script - components/plugins.sh

### Template Management Script - components/templates.sh



