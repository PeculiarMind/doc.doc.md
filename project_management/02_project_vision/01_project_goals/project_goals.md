# doc.doc.md Project Goals
The goal of this project to provide a set of command-line tools for processing document collections contained in a directory structure. The result of the processing is a set of markdown formatted documents that can be e.g. in obsidian or other markdown based tools. To easily manage documents in a directory structure.

The project is structured in a way that allows for easy extension and customization. The tools are designed to be flexible and adaptable to different use cases and requirements. The project is also designed to be easy to use, with clear documentation and examples provided. The project is intended to be used by home users, home-lab users that don't want to use a full-blown document management system, and anyone who wants to easily manage their documents in a directory structure.

The core of this project is the `doc.doc.sh` script, which is responsible for processing the documents in the specified directory structure. The script is designed to be modular and extensible, allowing for easy addition of new features and functionality. The script is also designed to be easy to use, with clear documentation and help system.

The script supports a variety of commands and options that allow users to customize the processing of their documents. The available commands and options are designed to be intuitive and easy to understand, making it easy for users to get started with the tool.

## Processing Documents

Command: `doc.doc.sh` `process` 

|long parameter|short parameter|description|required|default value|
|---|---|---|---|---|
|--input-directory|-d|The directory containing the documents to be processed.|true| |
|--output-directory|-o|The directory where the generated markdown files will be saved. Input directory structure will be mirrored to the output directory.|true| |
|--template|-t|The path to the markdown template that will be used for generating the markdown files.|false| Defaults to the built-in template |
|--include|-i|A comma-separated list of file extensions, glob patterns, or mime types to include in the processing.|false| |
|--exclude|-e|A comma-separated list of file extensions, glob patterns, or mime types to exclude from the processing.|false| |

Example usage:
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
Multiple `--include` and `--exclude` parameters can be used to specify different criteria for including or excluding files. The criteria can be a file extension (e.g. `.txt`), a glob pattern (e.g. `**/2024/**`), or a mime type (e.g. `application/pdf`). The script will process the documents in the input directory according to the specified criteria and generate markdown files in the output directory, mirroring the input directory structure in the following way:

- values provided within `--include` will be **ored** together, meaning that a file will be included if it matches at least one of the provided criteria.
- multiple --include parameters will be **anded** together, meaning that a file will be included only if it matches at least one criteria from each of the provided --include parameters.
- values provided within `--exclude` will be **ored** together, meaning that a file will be excluded if it matches at least one of the provided criteria.
- multiple --exclude parameters will be **anded** together, meaning that a file will be excluded only if it matches at least one criteria from each of the provided --exclude parameters.

### Example Explanation

**Include Logic:**
1. First `--include ".txt,.md,application/pdf"`: Files matching `.txt` **OR** `.md` **OR** `application/pdf`
2. Second `--include "**/2024/**"`: Files in any directory path containing `2024`
3. **Combined**: Files must match (`.txt` OR `.md` OR `pdf`) **AND** be in a `2024` directory

**Exclude Logic:**
1. First `--exclude ".log"`: Files with `.log` extension
2. Second `--exclude "**/temp/**"`: Files in any `temp` directory
3. **Combined**: Files matching `.log` **AND** being in a `temp` directory will be excluded

**Final Result:**
A file will be processed if:
- It has extension `.txt`, `.md`, or mime type `application/pdf`
- **AND** it's located within a `2024` directory path
- **AND NOT** (it has `.log` extension **AND** is in a `temp` directory)

**Practical Examples**

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

Command: `doc.doc.sh` `list` `plugins`   
* Lists all available plugins, both active and inactive.

Command: `doc.doc.sh` `list` `plugins` `active`  
* Lists all active plugins.

Command: `doc.doc.sh` `list` `plugins` `inactive`  
* Lists all inactive plugins.

Command: `doc.doc.sh` `activate` `--plugin <plugin_name>`
* Activates a plugin, making it available for use in the document processing.   

Command: `doc.doc.sh` `deactivate` `--plugin <plugin_name>`
* Deactivates a plugin, making it unavailable for use in the document processing.

Command: `doc.doc.sh` `install` `--plugin <plugin_name>`
* Installs a plugin, making it available for activation.

Command: `doc.doc.sh` `installed` `--plugin <plugin_name>`
* Checks if a plugin is installed.

|long parameter|short parameter|description|required|default value|
|---|---|---|---|---|
|--plugin|-p|The name of the plugin to activate or deactivate.|true| |

Command: `doc.doc.sh` `tree` 
* Displays a tree view of the plugins, showing their dependencies and activation status. Active plugins are highlighted in green, while inactive plugins are highlighted in red. The tree view provides a clear visual representation of the plugin ecosystem, making it easy to understand the relationships between plugins and their activation status.

