#!/bin/bash -e

echo "Processing liquibase tasks ..."
case "$1" in
    "update" )
        echo "Applying changelogs ..."
        sh /scripts/liquibase_update.sh
        ;;
esac