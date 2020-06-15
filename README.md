# Official Liquibase Docker images

[![Docker Auto Build](https://img.shields.io/docker/cloud/automated/liquibase/liquibase)][docker]

[docker]: https://hub.docker.com/r/liquibase/liquibase

This is the official repository for [Liquibase Command-line](https://download.liquibase.org/) images.

# docker

## MSSQL (SQL Server)

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>;" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> --liquibaseProLicenseKey="<PASTE LB PRO LICENSE KEY HERE>" generateChangeLog`


## PostgreSQL

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## MariaDB (MySQL)

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## DB2

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## Snowflake

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## Sybase

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## SQLite

`docker run --rm -v <PATH TO DB FILE>:/liquibase/<DB FILE NAME>.db -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:sqlite:/liquibase/<DB FILE NAME>.db" --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> generateChangeLog`

## Using Oracle or any other Host Located JDBC Libraries

`docker run --rm -v <JDBC LOCAL DIR>:/liquibase/lib -v <PATH TO CHANGELOG LOCAL DIR>:/liquibase/changelog liquibase/liquibase --classpath=/liquibase/lib/<JDBC JAR FILE> --url=<JDBC URL> --changeLogFile=/liquibase/changelog/<CHANGELOG NAME ie: "changelog.xml"> --username=<USERNAME> --password=<PASSWORD> generateChangeLog`