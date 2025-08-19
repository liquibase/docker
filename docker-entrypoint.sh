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
  # Only change directory if we detect relative paths being used (unless overridden)
  # Allow SHOULD_CHANGE_DIR to be set via environment variable to override automatic detection
  if [ -z "$SHOULD_CHANGE_DIR" ]; then
    SHOULD_CHANGE_DIR=false
  fi
  
  # Only perform automatic detection if SHOULD_CHANGE_DIR wasn't explicitly set
  if [ "$SHOULD_CHANGE_DIR" = "false" ]; then
    # Check if any arguments contain relative paths (not starting with / or containing :/ for URLs)
    for arg in "$@"; do
      # Convert argument to lowercase for case-insensitive matching
      lower_arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
      case "$lower_arg" in
        --changelogfile=*|--changelog-file=*|--defaultsfile=*|--defaults-file=*|--outputfile=*|--output-file=*)
          value="${arg#*=}"  # Use original arg to preserve case in the value
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
      # Convert argument to lowercase for case-insensitive matching
      lower_arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
      case "$lower_arg" in
        --defaultsfile=*|--defaults-file=*)
          value="${arg#*=}"  # Use original arg to preserve case in the value
          # If this is a relative path to a properties file, change directory
          if [[ "$value" != /* && "$value" != *://* && "$value" != "" ]]; then
            SHOULD_CHANGE_DIR=true
            break
          fi
          ;;
      esac
    done
  fi
  
  # Change directory only if we detected relative paths and the changelog directory exists
  if [ -d "/liquibase/changelog" ] && [ "$SHOULD_CHANGE_DIR" = true ]; then
    cd /liquibase/changelog
  fi
  
  # Set search path based on whether we changed directories
  EXTRA_SEARCH_PATH=""
  if [ -d "/liquibase/changelog" ]; then
    if [ "$SHOULD_CHANGE_DIR" = true ]; then
      # If we changed to changelog directory, search current directory (.) for relative paths
      EXTRA_SEARCH_PATH="--searchPath=./"
    else
      # If we stayed in /liquibase, search root (/) for absolute paths
      EXTRA_SEARCH_PATH="--searchPath=/"
    fi
  fi
  
  if [[ "$*" == *--defaultsFile* ]] || [[ "$*" == *--defaults-file* ]] || [[ "$*" == *--version* ]]; then
    ## Just run as-is, but add search path if needed
    if [ -n "$EXTRA_SEARCH_PATH" ]; then
      exec /liquibase/liquibase "$EXTRA_SEARCH_PATH" "$@"
    else
      exec /liquibase/liquibase "$@"
    fi
  else
    ## Include standard defaultsFile and search path
    if [ -n "$EXTRA_SEARCH_PATH" ]; then
      exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$EXTRA_SEARCH_PATH" "$@"
    else
      exec /liquibase/liquibase "--defaultsFile=/liquibase/liquibase.docker.properties" "$@"
    fi
  fi
fi