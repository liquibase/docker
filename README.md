## Official Liquibase Docker images

[![Docker Auto Build](https://img.shields.io/docker/cloud/automated/liquibase/liquibase)][docker]

[docker]: https://hub.docker.com/r/liquibase/liquibase

This is the official repository for [Liquibase](https://download.liquibase.org/) images.

## Supported Tags

The following tags are officially supported:

#### Overall Most Recent Build

The latest tag will be kept up to date with the most advanced Liquibase release.

-	`latest`

#### Latest Major/Minor Builds

These tags are kept up to date with the most recent patch release of each X.Y stream

- `4.9`
- `4.8`
- `4.7`
- `4.6`
- `4.5`
-	`4.4`
-	`4.3`
-	`4.2`
-	`4.1`
-	`3.10`

#### Specific Releases

Each specific release has an associated tag

- `4.9.0`
- `4.8.0`
- `4.7.1`
- `4.7.0`
- `4.6.2`
- `4.6.1`
- `4.5.0`
-	`4.4.3`
-	`4.4.2`
-	`4.4.1`
-	`4.4.0`
-	`4.3.5`
-	`4.3.4`
-	`4.3.3`
-	`4.3.2`
-	`4.3.1`
-	`4.3.0`
-	`4.2.2`
-	`4.2.0`
-	`4.1.1`
-	`4.1.0`
-	`3.10.3`

## Changelog Files

The docker image has a /liquibase/changelog volume in which the directory containing the root of your changelog tree can be mounted. Your `--changeLogFile` argument should list paths relative to this.

The /liquibase/changelog volume can also be used for commands that write output, such as `generateChangeLog`. Note that in this case (where liquibase should write a new file) you need to specify the absolute path to the changelog, i.e. prefix the path with `/liquibase/changelog/<PATH TO CHANGELOG FILE>`.

#### Example

If you have a local `c:\projects\my-project\src\main\resources\com\example\changelogs\root.changelog.xml` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --changeLogFile=com/example/changelogs/root.changelog.xml update`

To generate a new changelog file at this location, run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --changeLogFile=com/example/changelogs/root.changelog.xml generateChangeLog`

## Configuration File

If you would like to use a "default file" to specify arguments rather than passing them on the command line, include it in your changelog volume mount and reference it.

If specifying a custom liquibase.properties file, make sure you include `classpath=/liquibase/changelog` so Liquibase will continue to look for your changelog files there.   

#### Example

If you have a local `c:\projects\my-project\src\main\resources\liquibase.properties` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.properties update`

## Drivers and Extensions

The Liquibase docker container ships with drivers for many popular databases. If your driver is not included or if you have an extension, you can mount a local directory containing the jars to `/liquibase/classpath` and add the jars to your `classpath` setting. 

#### Example

If you have a local `c:\projects\my-project\lib\my-driver.jar` file, `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog -v c:\projects\my-project\lib:/liquibase/classpath liquibase/liquibase --classpath=/liquibase/changelog:/liquibase/classpath/my-driver.jar update`

### Notice for MySQL Users
Due to licensing restrictions for the MySQL driver, this container does not ship with the MySQL driver installed. Two options exist for loading this driver: 1. Create a new container from the `liquibase/liquibase` image. 2. Load this driver during runtime via an environment variable. 

#### New Container Example
Dockerfile
```dockerfile
FROM liquibase/liquibase

RUN lpm add mysql --global
```
Build
```shell
docker build . -t liquibase/liquibase-mysql
```

#### Runtime Example
```shell
docker run -e INSTALL_MYSQL=true liquibase/liquibase update
```

## Complete Examples

#### Specify everything via arguments 

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>;" --changeLogFile=com/example/changelog.xml --username=<USERNAME> --password=<PASSWORD> --liquibaseProLicenseKey="<PASTE LB PRO LICENSE KEY HERE>" update`

Using with [Liquibase Pro Environment Variables](https://docs.liquibase.com/concepts/basic/liquibase-environment-variables.html) example:
` docker run --env LIQUIBASE_COMMAND_USERNAME --env LIQUIBASE_COMMAND_PASSWORD --env LIQUIBASE_COMMAND_URL --env LIQUIBASE_PRO_LICENSE_KEY --env LIQUIBASE_COMMAND_CHANGELOG_FILE --rm -v <PATH TO CHANGELOG DIR>/changelogs:/liquibase/changelog liquibase/liquibase --log-level=info update`


#### Using a properties file

*liquibase.docker.properties file:*
```
classpath: /liquibase/changelog
url: jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>
changeLogFile: changelog.xml
username: <USERNAME>
password: <PASSWORD>
liquibaseProLicenseKey=<PASTE LB PRO LICENSE KEY HERE> 
```

*CLI:*
`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties update`  

or `docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties --changeLogFile=changelog.xml generateChangeLog` (the argument `--changeLogFile` wins against the defaultsFile)


#### Example JDBC Urls:

- MS SQL Server: `jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>`
- PostgreSQL: `jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>`
- MySQL: `jdbc:mysql://<IP OR HOSTNAME>:3306/<DATABASE>`
- MariaDB: `jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>`
- DB2: `jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>`
- Snowflake: `jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>`
- Sybase `jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>`
- SQLite: `jdbc:sqlite:/tmp/<DB FILE NAME>.db`

Note: If the database IP refers to a locally running docker container then one needs to specify host networking like `docker run --network=host -rm -v ...`
