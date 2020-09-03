#!/bin/sh
set -e

# first arg is `-*` (picks up `--*`, too)
if [ "${1#-}" != "$1" ]; then
	set -- /liquibase/liquibase "$@"
fi

exec "$@"