## 0001 Plugin Concept
 
 The system shall support a plugin architecture that allows users to extend functionality by adding or substituting analysis tools and report generators through configuration files.
 
 **Rationale:**
 - Enables customization and adaptability to different user needs without modifying the core codebase
 - Facilitates integration of third-party tools and future enhancements
 - Supports a modular design, allowing users to pick and choose components based on their requirements

 **Implementation Details:**
Plugins are located in the `scripts/plugins/` directory, organized by operating system (e.g., `ubuntu`, `alpine`). Each plugin consists of:
 
 - A descriptor file (e.g., `descriptor.json`) that defines:
   - Plugin name and version
   - Supported operating systems
   - Required dependencies
   - Command-line instructions for execution
   - Optional installation and verification commands
 - An optional installation script (e.g., `install.sh`) to automate the setup of required tools.
 
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
    "consumes":{
        "file_path_absolute": {
            "type": "string",
            "description": "Path to the file to be analyzed."
        }    
    },
    "commandline": "read -r file_created file_last_modified file_owner file_size < <(stat -c %W,%Y,%U,%B ${file_path_absolute})",
    "install_commandline": "read -r plugin_successfully_installed < <(./install.sh 2>&1 >/dev/null && echo 'true' || echo 'false')",
    "check_commandline": "read -r plugin_works < <(which stat > /dev/null 2>&1 && echo 'true' || echo 'false')"
}
 ```


 **Usage:**
 - Users can add new plugins by creating a new directory under the appropriate OS folder and providing the necessary files.
 - The system will read the plugin descriptors at runtime to determine available tools and their configurations.
 - Users can enable or disable specific plugins through a configuration file or command-line options.

 
 
 