#!/bin/bash
set -e

if [[ "$INSTALL_MYSQL" ]]; then
  lpm add mysql --global
fi

if [[ "$1" != "history" ]] && [[ "$1" != "init" ]] && type "$1" > /dev/null 2>&1; then
  ## First argument is an actual OS command (except if the command is history or init as it is a liquibase command). Run it
  exec "$@"
else
  # Check if changelog directory exists (common mount point) and change to it
  # This makes Docker behavior match CLI behavior for relative paths
  # Only change directory if we detect relative paths being used
  SHOULD_CHANGE_DIR=false
  
  # Check if any arguments contain relative paths (not starting with / or containing :/ for URLs)
  for arg in "$@"; do
    case "$arg" in
      --changelogFile=*|--changelog-file=*|--defaultsFile=*|--defaults-file=*|--outputFile=*|--output-file=*)
        value="${arg#*=}"
        # If the value doesn't start with / and doesn't contain :/ (for URLs), it's likely a relative path
        if [[ "$value" != /* && "$value" != *://* && "$value" != "" ]]; then
          SHOULD_CHANGE_DIR=true
          break
        fi
        ;;
    esac
  done
  
  # Also check if there's a properties file being used that might contain relative paths
  for arg in "$@"; do
    case "$arg" in
      --defaultsFile=*|--defaults-file=*)
        value="${arg#*=}"
        # If this is a relative path to a properties file, change directory
        if [[ "$value" != /* && "$value" != *://* && "$value" != "" ]]; then
          SHOULD_CHANGE_DIR=true
          break
        fi
        ;;
    esac
  done
  
  # Change directory only if we detected relative paths and the changelog directory exists
  if [ -d "/liquibase/changelog" ] && [ "$SHOULD_CHANGE_DIR" = true ]; then
    cd /liquibase/changelog
  fi
  
  if [[ "$*" == *--defaultsFile* ]] || [[ "$*" == *--defaults-file* ]] || [[ "$*" == *--version* ]]; then
    ## Just run as-is
    exec /liquibase/liquibase "$@"
  else
    ## Include standard defaultsFile
    exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
  fi
fi