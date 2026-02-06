## 0001 Plugin Concept
 
 The system shall support a plugin architecture that allows users to extend functionality by adding or substituting analysis tools and report generators through configuration files.
 
 **Rationale:**
 - Enables customization and adaptability to different user needs without modifying the core codebase
 - Facilitates integration of third-party tools and future enhancements
 - Supports a modular design, allowing users to pick and choose components based on their requirements

 **Implementation Details:**
Plugins are located in the `scripts/plugins/` directory, organized by operating system (e.g., `ubuntu`, `alpine`). Each plugin is contained in a specific directory and consists of:
 
 - A descriptor file named `descriptor.json` that defines:
   - Plugin name and version
   - Command-line instructions for execution
   - Commandl-line for installation and 
   - Commandl-line for verification if the plugin can be used
 - Optional different scripts (e.g., `install.sh`) to enable more complex setup of required tools.
 
 **Example Structure:**
 ```
 scripts/
 └── plugins/
     └── all/
     └── ubuntu/
         ├── stat/
         │   ├── descriptor.json
         │   └── install.sh
         └── <some_plugin>/
             ├── descriptor.json
             └── install.sh
 ```

**Plugin Descriptor Example (`descriptor.json`):**
 ```json
{
    "name": "stat",
    "description": "Retrieves file statistics such as last modified time, size, and owner using the stat command.",
    "active": true,
    "processes": {
        "mime_types": [],
        "file_extensions": []
    },
    "consumes":{
        "file_path_absolute": {
            "type": "string",
            "description": "Path to the file to be analyzed."
        }    
    },
    "provides": {
        "file_last_modified": {
            "type": "integer",
            "description": "Last modified time as an Unix timestamp."
        },
        "file_size": {
            "type": "integer",
            "description": "Size of the file in bytes."
        },
        "file_owner": {
            "type": "string",
            "description": "Owner of the file."
        }
    },
    "execute_commandline": "read -r file_created file_last_modified file_owner file_size < <(stat -c %W,%Y,%U,%B ${file_path_absolute})",
    "install_commandline": "read -r plugin_successfully_installed < <(./install.sh 2>&1 >/dev/null && echo 'true' || echo 'false')",
    "check_commandline": "read -r plugin_works < <(which stat > /dev/null 2>&1 && echo 'true' || echo 'false')"
}
 ```

**Descriptor Attributes:**

The plugin descriptor is a JSON file that defines the plugin's metadata, capabilities, and execution commands. Each descriptor must include the following top-level attributes:

| Name                      | Type             | Description                                                                                                                                                                                                                                                            | Required | Default |
| ------------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| name                      | string           | A human readable, unique identified for the plugin.                                                                                                                                                                                                                    | yes      |         |
| description               | string           | A short description of the plugin and its capabilities                                                                                                                                                                                                                 | yes      |         |
| active                    | boolean          | Whether the plugin is enabled. Set to `false` to disable a plugin without removing it.                                                                                                                                                                                 | no       | false   |
| processes                 | object           | Containes two arrays describing which file types this plugin is able to process. If not specified, or both arrays are not specified or empty this plugin is intended to be able to process files of any type. Everything specified will be evaluated as logical or'ed. | no       | *       |
| processes.mime_types      | array of string  | MIME types the plugin processes. Use empty array `[]` to handle all types. MIME types can be determined using `file -b --mime-type <filepath>`. Examples: `["application/pdf"]`, `["image/png", "image/jpeg"]`                                                         | no       |         |
| processes.file_extensions | array of strings | File extensions the plugin processes. Use empty array `[]` to handle all extensions. Examples: `[".pdf"]`, `[".md", ".txt"]`.                                                                                                                                          | no       |         |
| consumes                  | object           | Describes which kind parameters are required to execute this plugin.                                                                                                                                                                                                   | yes      |         |
| provides                  | object           | Describes which kind of parameters the plugin "returns".                                                                                                                                                                                                               | no       |         |
| execute_commandline       | string           | A command line to execute the plugin. It is executed by the toolkit in the plugins directory.                                                                                                                                                                          | yes      |         |
| install_commandline       | string           | A command line to install the plugin. It is executed by the toolkit in the plugins directory.                                                                                                                                                                          | yes      |         |
| check_commandline         | string           | A command line to check if the plugin is installed. It is executed by the toolkit in the plugins directory.                                                                                                                                                            | yes      |         |


The toolkit uses `consumes` and `provides` to determine plugin execution order automatically. Plugins execute only when all their consumed data is available. The `processes` attribute filters which files are passed to each plugin based on type or extension.


 **Usage:**
 - Users can add new plugins by creating a new directory under the appropriate OS folder and providing the necessary files.
 - The system will read the plugin descriptors at runtime to determine available tools and their configurations.
 - Users can enable or disable specific plugins through a configuration file or command-line options.

 
 
 