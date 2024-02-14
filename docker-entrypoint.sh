#!/bin/bash
set -e

if [[ "$INSTALL_MYSQL" ]]; then
  lpm add mysql --global
fi

if [[ "$1" != "history" ]] && type "$1" > /dev/null 2>&1; then
  ## First argument is an actual OS command (except if the command is history as it is a liquibase command). Run it
  exec "$@"
elif [[ "$1" == "init" && "$2" == "h2" ]]; then
  ## Liquibase initialization command for H2
  exec /liquibase/liquibase "init h2"
else
  if [[ "$*" == *--defaultsFile* ]] || [[ "$*" == *--defaults-file* ]] || [[ "$*" == *--version* ]]; then
    ## Just run as-is
    exec /liquibase/liquibase "$@"
  else
    ## Include standard defaultsFile
    exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
  fi
fi
