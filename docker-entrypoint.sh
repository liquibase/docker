#!/bin/bash
set -e

#if [[ "$*" == *--defaultsFile* ]] && [[ -f "/liquibase/liquibase.properties" ]]; then
#    ## Move standard liquibase.properties file out of the way so there is no conflict with the passed version
#    mv /liquibase/liquibase.properties /liquibase/liquibase.properties.bak
#fi

if [[ "$*" == *--defaultsFile* ]]; then
  ## Just run as-is
  /liquibase/liquibase "$@"
else
  ## Include standard defaultsFile
  /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
fi
