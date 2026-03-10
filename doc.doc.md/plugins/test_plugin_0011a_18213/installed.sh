#!/bin/bash
jq -n --argjson v true '{installed: $v}'
exit 0
