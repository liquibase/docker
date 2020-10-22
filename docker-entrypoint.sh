#!/bin/bash
set -e

cp liquibase.base.properties liquibase.properties
printf "\n" >> liquibase.properties


for varname in "${!LIQUIBASE_@}"; do
  propName="${varname/LIQUIBASE_/}"
  propName="${propName/_/}"
  propValue="${!varname}"

  printf "${propName}: ${propValue}\n" >> liquibase.properties
done

/liquibase/liquibase "$@"
