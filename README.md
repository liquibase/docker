
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

-	`4.2`
-	`4.1`
-	`3.10`

#### Specific Releases

Each specific release has an associated tag

-	`4.2.2`
-	`4.2.0`
-	`4.1.1`
-	`4.1.0`
-	`3.10.3`

## Changelog Files

The docker image has a /liquibase/changelog volume in which the directory containing the root of your changelog tree can be mounted. Your `--changeLogFile` argument should list paths relative to this.

The /liquibase/changelog volume can also be used for commands that write output, such as `generateChangeLog`

#### Example

If you have a local `c:\projects\my-project\src\main\resources\com\example\changelogs\root.changelog.xml` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog --changeLogFile=com/example/changelogs/root.changelog.xml update`   

## Configuration File

If you would like to use a "default file" to specify arguments rather than passing them on the command line, include it in your changelog volume mount and reference it.

If specifying a custom liquibase.properties file, make sure you include `classpath=/liquibase/changelog` so Liquibase will continue to look for your changelog files there.   

#### Example

If you have a local `c:\projects\my-project\src\main\resources\liquibase.properties` file, you would run `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog --defaultsFile=/liquibase/changelog/liquibase.properties update`

## Drivers and Extensions

The Liquibase docker container ships with drivers for many popular databases. If your driver is not included or if you have an extension, you can mount a local dirctory containing the jars to `/liquibase/classpath` and add the jars to your `classpath` setting.   

#### Example

If you have a local `c:\projects\my-project\lib\my-driver.jar` file, `docker run --rm -v c:\projects\my-project\src\main\resources:/liquibase/changelog -v c:\projects\my-project\lib:/liquibase/classpath --classpath=/liquibase/changelog:/liquibase/classpath/my-driver.jar update`

## Complete Examples

#### Specify everything via arguments 

`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --url="jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>;" --changeLogFile=com/example/changelog.xml --username=<USERNAME> --password=<PASSWORD> --liquibaseProLicenseKey="<PASTE LB PRO LICENSE KEY HERE>" update`

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
`docker run --rm -v <PATH TO CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --defaultsFile=/liquibase/changelog/liquibase.docker.properties update`

#### Example JDBC Urls:

- MS SQL Server: `jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>`
- PostgreSQL: `jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>`
- MySQL: `jdbc:mysql://<IP OR HOSTNAME>:3306/<DATABASE>`
- MariaDB: `jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>`
- DB2: `jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>`
- Snowflake: `jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>`
- Sybase `jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>`
- SQLite: `jdbc:sqlite:/tmp/<DB FILE NAME>.db`
