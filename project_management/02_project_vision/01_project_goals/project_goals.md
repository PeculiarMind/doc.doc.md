# doc.doc.md Project Goals

The goal of this project is to provide a command-line tool for processing document collections within directory structures. The tool prioritizes flexibility and customization while reusing existing tools wherever possible to avoid reinventing the wheel. The output consists of markdown-formatted documents that can be used in Obsidian or other markdown-based tools for easy document management.

The project is structured to support easy extension and customization. The tool is designed to be flexible and adaptable to different use cases and requirements. It targets home users, home-lab enthusiasts, and anyone who wants straightforward document management without deploying a full-blown document management system. Clear documentation and examples are provided to ensure ease of use.

The core of this project is the `doc.doc.sh` script, which processes documents in the specified directory structure. The script is modular and extensible, allowing new features and functionality to be added through plugins. A clear documentation and help system makes the script accessible to users.

The script supports a variety of commands and options for customizing document processing. The available commands and options are designed to be intuitive and user-friendly.

## Processing Documents

**Command:** `doc.doc.sh process`

**Parameters:**

| Long Parameter | Short Parameter | Description | Required | Default Value |
|---|---|---|---|---|
| `--input-directory` | `-d` | The directory containing the documents to be processed. | true | |
| `--output-directory` | `-o` | The directory where the generated markdown files will be saved. The input directory structure will be mirrored to the output directory. | true | |
| `--template` | `-t` | The path to the markdown template used for generating the markdown files. | false | Built-in template |
| `--include` | `-i` | A comma-separated list of file extensions, glob patterns, or MIME types to include in the processing. | false | |
| `--exclude` | `-e` | A comma-separated list of file extensions, glob patterns, or MIME types to exclude from the processing. | false | |

**Example Usage:**
```bash
doc.doc.sh process 
    --input-directory /path/to/input \
    --output-directory /path/to/output \
    --template /path/to/template.md \
    --include ".txt,.md,application/pdf" \
    --include "**/2024/**" \
    --exclude ".log" \
    --exclude "**/temp/**"
``` 

Multiple `--include` and `--exclude` parameters can be used to specify different filtering criteria. The criteria can be:
- A file extension (e.g., `.txt`)
- A glob pattern (e.g., `**/2024/**`)  
- A MIME type (e.g., `application/pdf`)

The script processes documents in the input directory according to the specified criteria and generates markdown files in the output directory, mirroring the input directory structure. The filtering logic works as follows:

- Values within a single `--include` parameter are **ORed** together (a file matches if it satisfies at least one criterion)
- Multiple `--include` parameters are **ANDed** together (a file must match at least one criterion from each `--include` parameter)
- Values within a single `--exclude` parameter are **ORed** together (a file is excluded if it matches at least one criterion)
- Multiple `--exclude` parameters are **ANDed** together (a file is excluded only if it matches at least one criterion from each `--exclude` parameter)

### Example Explanation

**Include Logic:**
1. First `--include ".txt,.md,application/pdf"`: Files matching `.txt` **OR** `.md` **OR** `application/pdf`
2. Second `--include "**/2024/**"`: Files in any directory path containing `2024`
3. **Combined**: Files must match (`.txt` OR `.md` OR `application/pdf`) **AND** be in a `2024` directory

**Exclude Logic:**
1. First `--exclude ".log"`: Files with `.log` extension
2. Second `--exclude "**/temp/**"`: Files in any `temp` directory
3. **Combined**: Files are excluded only if they have `.log` extension **AND** are in a `temp` directory

**Final Result:**

A file will be processed if:
- It has extension `.txt`, `.md`, or MIME type `application/pdf`
- **AND** it's located within a `2024` directory path
- **AND NOT** (it has `.log` extension **AND** is in a `temp` directory)

**Practical Examples:**

| File Path | Extension | Included? | Reason |
|-----------|-----------|-----------|--------|
| `/path/to/input/2024/notes.txt` | `.txt` | ✅ Yes | Matches `.txt` AND in `2024` path |
| `/path/to/input/2024/report.md` | `.md` | ✅ Yes | Matches `.md` AND in `2024` path |
| `/path/to/input/2024/doc.pdf` | `.pdf` | ✅ Yes | Matches `application/pdf` AND in `2024` path |
| `/path/to/input/2023/notes.txt` | `.txt` | ❌ No | Matches `.txt` but NOT in `2024` path |
| `/path/to/input/2024/data.csv` | `.csv` | ❌ No | In `2024` path but doesn't match any include extension |
| `/path/to/input/2024/temp/debug.log` | `.log` | ❌ No | Excluded (`.log` AND in `temp` directory) |
| `/path/to/input/2024/temp/notes.txt` | `.txt` | ✅ Yes | In `temp` but NOT `.log` extension |
| `/path/to/input/2024/backup/file.log` | `.log` | ✅ Yes | `.log` extension but NOT in `temp` directory |


## Plugin Management

**Command:** `doc.doc.sh list plugins`  
Lists all available plugins, both active and inactive.

**Command:** `doc.doc.sh list plugins active`  
Lists all active plugins.

**Command:** `doc.doc.sh list plugins inactive`  
Lists all inactive plugins.

**Command:** `doc.doc.sh activate --plugin <plugin_name>`  
Activates a plugin, making it available for use in document processing.

**Command:** `doc.doc.sh deactivate --plugin <plugin_name>`  
Deactivates a plugin, making it unavailable for use in document processing.

**Command:** `doc.doc.sh install --plugin <plugin_name>`  
Installs a plugin, making it available for activation.

**Command:** `doc.doc.sh installed --plugin <plugin_name>`  
Checks if a plugin is installed.

**Parameters:**

| Long Parameter | Short Parameter | Description | Required | Default Value |
|---|---|---|---|---|
| `--plugin` | `-p` | The name of the plugin to activate, deactivate, install, or check. | true | |

**Command:** `doc.doc.sh tree`  
Displays a tree view of the plugins, showing their dependencies and activation status. Active plugins are highlighted in green, while inactive plugins are highlighted in red. The tree view provides a clear visual representation of the plugin ecosystem, making it easy to understand plugin relationships and activation status.


## Plugin Execution
doc.doc.sh executes active plugins in a specific order based on their dependencies. The execution order is determined by performing a topological sort on the plugin dependency graph. This ensures that plugins are executed in the correct sequence, with dependencies being executed before the plugins that depend on them. Each plugin receives the input parameters as a json object. Consequently plugins create output in the form of a json object that is written to stdout. This output will be consumed and processed by the doc.doc.md framework. 



