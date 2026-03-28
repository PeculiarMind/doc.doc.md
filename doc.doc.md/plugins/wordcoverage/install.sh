#!/bin/bash
# wordcoverage plugin - install command
# wordcoverage requires no external tools.
# Output: JSON {"success": bool, "message": string} to stdout

jq -n '{success: true, message: "wordcoverage requires no external tools."}'
exit 0
