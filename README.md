# Official Liquibase Docker Images

## 🚨 Notice: New Official Liquibase Docker Image 🚨

We are excited to announce that a new official Liquibase Docker image is now available at [https://hub.docker.com/_/liquibase](https://hub.docker.com/_/liquibase) starting with liquibase 4.27.0 and newer. We recommend all users to start using this image for the latest updates and support. Any versions prior to 4.27.0 will only be available on the existing `liquibase/liquibase` community image.

### 🔧 Action Required

Please update your Dockerfiles and scripts to pull from the new official image:

## Dockerfile

```dockerfile
FROM liquibase:latest
```

## Scripts

```bash
docker pull liquibase
```

In the future, we will stop updating the community `liquibase/liquibase` Docker image. Transition to the new official image to ensure you continue receiving updates and support.

For any questions or support, please visit our [Liquibase Community Forum](https://forum.liquibase.org/).

---

This is the community repository for [Liquibase](https://download.liquibase.org/) images.

## 🚨 BREAKING CHANGE

Support for Snowflake database has been moved from the external extension liquibase-snowflake into the main Liquibase artifact. This means that Snowflake is now included in the main docker image. If you are using the snowflake extension, remove it from your lib directory or however you are including it in your project. If you are using the Docker image, use the main v4.12+ as there will no longer be a snowflake separate docker image produced. The latest separate Snowflake image will be v4.11. You need to update your reference to either latest to use the main one that includes Snowflake or the version tag you prefer. <https://github.com/liquibase/liquibase/pull/2841>

## 🏷️ Supported Tags

The following tags are officially supported and can be found on [Docker Hub](https://hub.docker.com/r/liquibase/liquibase/tags):

- `liquibase/liquibase:<version>`
- `liquibase/liquibase:<version>-alpine`

## 📦 Using the Docker Image

### 🏷️ Standard Image

The `liquibase/liquibase:<version>` image is the standard choice. Use it as a disposable container or a foundational building block for other images.

For examples of extending the standard image, see the [standard image examples](https://github.com/liquibase/docker/tree/main/examples).

### 🏷️ Alpine Image

The `liquibase/liquibase:<version>-alpine` image is a lightweight version designed for environments with limited resources. It is built on Alpine Linux and has a smaller footprint.

For examples of extending the alpine image, see the [alpine image examples](https://github.com/liquibase/docker/tree/main/examples).

### 📄 Using the Changelog File

Mount your changelog directory to the `/liquibase/changelog` volume and use relative paths for the `--changeLogFile` argument.

#### Example

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --changeLogFile=changelog.xml update
```

### ⚙️ Using a Configuration File

To use a default configuration file, mount it in your liquibase.properties file and reference it with the `--defaultsFile` argument.

#### Example

```shell
docker run --rm -v /path/to/liquibase.properties:/liquibase/liquibase.properties/liquibase --defaultsFile=liquibase.properties update
```

### 📚 Including Drivers and Extensions

Mount a local directory containing additional jars to `/liquibase/lib`.

#### Example

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog -v /path/to/lib:/liquibase/lib liquibase/liquibase update
```

### 🔍 MySQL Users

Due to licensing restrictions, the MySQL driver is not included. Add it either by extending the image or during runtime via an environment variable.

#### Extending the Image

Dockerfile:

```dockerfile
FROM liquibase:latest

RUN lpm add mysql --global
```

Build:

```shell
docker build . -t liquibase-mysql
```

#### Runtime

```shell
docker run -e INSTALL_MYSQL=true liquibase/liquibase update
```

## 🛠️ Complete Example

Here is a complete example using environment variables and a properties file:

### Environment Variables Example

```shell
docker run --env LIQUIBASE_COMMAND_USERNAME --env LIQUIBASE_COMMAND_PASSWORD --env LIQUIBASE_COMMAND_URL --env LIQUIBASE_PRO_LICENSE_KEY --env LIQUIBASE_COMMAND_CHANGELOG_FILE --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --log-level=info update
```

### Properties File Example

`liquibase.docker.properties` file:

```properties
searchPath: /liquibase/changelog
url: jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>
changeLogFile: changelog.xml
username: <USERNAME>
password: <PASSWORD>
liquibaseProLicenseKey=<PASTE LB PRO LICENSE KEY HERE>
```

CLI:

```shell
docker run --rm -v /path/to/changelog:/liquibase/changelog liquibase/liquibase --defaultsFile=liquibase.docker.properties update
```

## 🔗 Example JDBC URLs

- MS SQL Server: `jdbc:sqlserver://<IP OR HOSTNAME>:1433;database=<DATABASE>`
- PostgreSQL: `jdbc:postgresql://<IP OR HOSTNAME>:5432/<DATABASE>?currentSchema=<SCHEMA NAME>`
- MySQL: `jdbc:mysql://<IP OR HOSTNAME>:3306/<DATABASE>`
- MariaDB: `jdbc:mariadb://<IP OR HOSTNAME>:3306/<DATABASE>`
- DB2: `jdbc:db2://<IP OR HOSTNAME>:50000/<DATABASE>`
- Snowflake: `jdbc:snowflake://<IP OR HOSTNAME>/?db=<DATABASE>&schema=<SCHEMA NAME>`
- Sybase: `jdbc:jtds:sybase://<IP OR HOSTNAME>:/<DATABASE>`
- SQLite: `jdbc:sqlite:/tmp/<DB FILE NAME>.db`

For more details, visit our [Liquibase Documentation](https://docs.liquibase.com/).

<img referrerpolicy="no-referrer-when-downgrade" src="https://static.scarf.sh/a.png?x-pxid=fc4516b5-fc01-40ce-849b-f97dd7be2a34" />
