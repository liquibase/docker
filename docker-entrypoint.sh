#!/bin/bash
set -e

# Function to retrieve the license key from Secrets Manager
retrieve_license_key() {
  local LICENSE_KEY
  LICENSE_KEY=$(aws secretsmanager get-secret-value --secret-id MyLicenseKey --query SecretString --output text)
  echo "$LICENSE_KEY" > /liquibase/liquibase-pro-license.key
}

if [[ "$INSTALL_MYSQL" ]]; then
  lpm add mysql --global
fi

if [[ "$1" != "history" ]] && [[ "$1" != "init" ]] && type "$1" > /dev/null 2>&1; then
  ## First argument is an actual OS command (except if the command is history or init as it is a liquibase command). Run it
  exec "$@"
else
  if [[ "$*" == *--defaultsFile* ]] || [[ "$*" == *--defaults-file* ]] || [[ "$*" == *--version* ]]; then
    ## Just run as-is
    exec /liquibase/liquibase "$@"
  else
    ## Include standard defaultsFile
    exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
  fi
fi
