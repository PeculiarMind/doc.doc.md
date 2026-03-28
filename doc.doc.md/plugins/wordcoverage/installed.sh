#!/bin/bash
# wordcoverage plugin - installed check
# No external dependencies required.
# Output: JSON {"installed": true} to stdout
# Exit code: always 0

jq -n '{installed: true}'
exit 0
