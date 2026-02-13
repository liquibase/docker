#!/bin/bash
set -e

# Check for license file in multiple locations and set DATDB_LICENSE
if [ -f "/liquibase/license/license.lic" ]; then
    export DATDB_LICENSE="/liquibase/license/license.lic"
elif [ -f "/liquibase/license/myLicense.lic" ]; then
    export DATDB_LICENSE="/liquibase/license/myLicense.lic"
fi

# Configure SSH known hosts for common providers if not already configured
if [ -n "$SSH_AUTH_SOCK" ] && [ ! -f /liquibase/.ssh/known_hosts ]; then
    ssh-keyscan -t ed25519 github.com gitlab.com bitbucket.org ssh.dev.azure.com >> /liquibase/.ssh/known_hosts 2>/dev/null || true
fi

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
