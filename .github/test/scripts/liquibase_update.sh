#!/bin/bash
: ${CHANGELOG_FILE:="/changelog/changelog.sql"}
: ${DEFAULTS_FILE:="/liquibase/changelog/liquibase-mssql.properties"}

echo "Applying changes to the database. Changelog: $CHANGELOG_FILE"
liquibase --defaultsFile="$DEFAULTS_FILE"  --changeLogFile="$CHANGELOG_FILE" update