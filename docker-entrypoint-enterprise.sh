#!/bin/bash
set -e

# Check for license file in multiple locations and set DATDB_LICENSE
if [ -f "/liquibase/license/license.lic" ]; then
    export DATDB_LICENSE="/liquibase/license/license.lic"
elif [ -f "/liquibase/license/myLicense.lic" ]; then
    export DATDB_LICENSE="/liquibase/license/myLicense.lic"
fi

# Do NOT change to /liquibase/project directory by default
# Liquibase Enterprise writes daticaldb.log to the current working directory,
# which causes permission denied errors if the working directory is a mounted volume
# Users should either:
# 1. Mount with appropriate write permissions
# 2. Use absolute paths for changelog files
# 3. Set WORKDIR explicitly if needed
# Stay in /liquibase which is owned by the liquibase user

# Execute command
if [[ "$1" != "history" ]] && type "$1" > /dev/null 2>&1; then
    # First argument is an actual OS command. Run it directly
    exec "$@"
else
    # Default to hammer commands for Liquibase Enterprise
    # If first argument is 'hammer', remove it since we're calling hammer anyway
    if [ "$1" = "hammer" ]; then
        shift
    fi
    exec hammer "$@"
fi
