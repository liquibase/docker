# Official Liquibase Docker images

[![Docker Auto Build](https://img.shields.io/docker/cloud/automated/liquibase/liquibase)][docker]

[docker]: https://hub.docker.com/r/liquibase/liquibase

This is the official repository for [Liquibase](https://download.liquibase.org/) images.

## BREAKING CHANGE

Support for Snowflake database has been moved from the external extension liquibase-snowflake into the main Liquibase artifact. This means that Snowflake is now included in the main docker image. If you are using the snowflake extension remove it from your lib directory or however you are including it in your project. If you are using the Docker image, use the main v4.12+ as there will no longer be a snowflake separate docker image produced.  The latest separate Snowflake image will be v4.11. You need to update your reference to either latest to use the main one that includes Snowflake or the version tag you prefer. <https://github.com/liquibase/liquibase/pull/2841>

## Supported Tags

The following tags are officially supported:

https://hub.docker.com/r/liquibase/liquibase/tags

### liquibase alpine

The `liquibase:<version>-alpine` tag is a slimmed-down version of the Liquibase Docker container. It is designed to be lightweight and have a smaller footprint, making it suitable for environments with limited resources or when only the essential functionality is required.

#### Functionality and Purpose

The `liquibase:<version>-alpine` container provides the core functionality of Liquibase, which includes database change management and version control. It allows you to define and manage database schemas, apply and roll back changes, and track the evolution of your database over time.

#### Usage and Prerequisites

To use the `liquibase:<version>-alpine` container, you need to have Docker installed on your system. Please refer to the official Docker documentation for instructions on how to install Docker: [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)

#### Examples and Usage Scenarios

Here are some examples to demonstrate the capabilities of `liquibase-slim`:

1. **Initializing a new Liquibase project**:

```shell
docker run --rm -v $(pwd):/liquibase/changelog liquibase/liquibase:<version>-alpine \
  --classpath=/liquibase/changelog \
  --changeLogFile=changelog.xml \
  --url="jdbc:postgresql://localhost:5432/mydb" \
  --username=myuser \
  --password=mypassword \
  generateChangeLog
```

2. **Applying database changes**:

```shell
docker run --rm -v $(pwd):/liquibase/changelog liquibase/liquibase:<version>-alpine \
  --classpath=/liquibase/changelog \
  --changeLogFile=changelog.xml \
  --url="jdbc:postgresql://localhost:5432/mydb" \
  --username=myuser \
  --password=mypassword \
  update
```

## Changelog File

The docker image has a /liquibase/changelog volume in which the directory containing the root of your changelog tree can be mounted. Your `--changeLogFile` argument should list paths relative to this.

The /liquibase/changelog volume can also be used for commands that write output, such as `generateChangeLog`. Note that in this case (where liquibase should write a new file) you need to specify the absolute path to the changelog, i.e. prefix the path with `/liquibase/changelog/<PATH TO CHANGELOG FILE>`.

### Changelog File Example

If you have a local `c:\projects\my-project\src\main\resources\com\example\changelogs\root.changelog.xml` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --changeLogFile=changelog/com/example/changelogs/root.changelog.xml update`

To generate a new changelog file at this location, run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --changeLogFile=changelog/com/example/changelogs/root.changelog.xml generateChangeLog`

## Configuration File

If you would like to use a "default file" to specify arguments rather than passing them on the command line, include it in your changelog volume mount and reference it.

If specifying a custom liquibase.properties file, make sure you include `searchPath=/liquibase/changelog` so Liquibase will continue to look for your changelog files there.

### Configuration File Example

If you have a local `c:\projects\my-project\src\main\resources\liquibase.properties` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.properties update`

## Drivers and Extensions

The Liquibase docker container ships with drivers for many popular databases. If your driver is not included or if you have an extension, you can mount a local directory containing the jars to `/liquibase/lib`.

### Driver and Extensions Example

If you have a local `c:\projects\my-project\lib\my-driver.jar` file, `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog -v c:\projects\my-project\lib:/liquibase/lib liquibase/liquibase update`

### Notice for MySQL Users

Due to licensing restrictions for the MySQL driver, this container does not ship with the MySQL driver installed. Two options exist for loading this driver: 1. Create a new container from the `liquibase/liquibase` image. 2. Load this driver during runtime via an environment variable.

### New Container Example

Dockerfile

```dockerfile
FROM liquibase/liquibase

RUN lpm add mysql --global
```

Build

```shell
docker build . -t liquibase/liquibase-mysql
```

### Runtime Example

```shell
docker run -e INSTALL_MYSQL=true liquibase/liquibase update
```

## Complete Examples

### Specify everything via arguments

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>;" --changeLogFile=com/example/changelog.xml --username=<USERNAME> --password=<PASSWORD> --liquibaseProLicenseKey="<PASTE LB PRO LICENSE KEY HERE>" update`

Using with [Liquibase Pro Environment Variables](https://docs.liquibase.com/concepts/basic/liquibase-environment-variables.html) example:
`docker run --env LIQUIBASE_COMMAND_USERNAME --env LIQUIBASE_COMMAND_PASSWORD --env LIQUIBASE_COMMAND_URL --env LIQUIBASE_PRO_LICENSE_KEY --env LIQUIBASE_COMMAND_CHANGELOG_FILE --rm -v <PATH TO CHANGELOG DIR>/changelogs:/liquibase/changelog liquibase/liquibase --log-level=info update`

### Using a properties file

*liquibase.docker.properties file:*

```dockerfile
searchPath: /liquibase/changelog
url: jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>
changeLogFile: changelog.xml
username: <USERNAME>
password: <PASSWORD>
liquibaseProLicenseKey=<PASTE LB PRO LICENSE KEY HERE>
```

*CLI:*

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties update`
or
`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties --changeLogFile=changelog.xml generateChangeLog` (the argument `--changeLogFile` wins against the defaultsFile)

### Example JDBC Urls

- MS SQL Server: `jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>`
- PostgreSQL: `jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>`
- MySQL: `jdbc:mysql://<IP OR HOSTNAME>:3306/<DATABASE>`
- MariaDB: `jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>`
- DB2: `jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>`
- Snowflake: `jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>`
- Sybase `jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>`
- SQLite: `jdbc:sqlite:/tmp/<DB FILE NAME>.db`

Note: If the database IP refers to a locally running docker container then one needs to specify host networking like `docker run --network=host -rm -v ...`

### Adding Native Executors

The recommended path for adding native executors/binaries such as Oracle SQL*Plus, Microsoft SQLCMD, Postgres PSQL, or the AWS CLI is to extend the liquibase/liquibase Dockerfile.  Examples are provided in the [Examples](/examples) Directory.

