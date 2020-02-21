# docker

## PostgreSQL

`docker run liquibase/liquibase --driver=org.postgresql.Driver --classpath=/usr/share/java/postgresql.jar --url="jdbc:postgresql://<IP OR HOSTNAME>:<PORT>/<DATABASE>" --changeLogFile=changelog.xml --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## MariaDB (MySQL)

`docker run liquibase/liquibase --driver=org.mariadb.jdbc.Driver --classpath=/usr/share/java/mariadb-java-client.jar --url="jdbc:mariadb://<IP OR HOSTNAME>:<PORT>/<SCHEMA NAME>" --changeLogFile=changelog.xml --username=<USERNAME> --password=<PASSWORD> generateChangeLog`

## Using Host Located JDBC Libraries
`docker run -v <JDBC DIR>:/liquibase/jdbc -v <CHANGELOG DIR>:/liquibase/changelog liquibase/liquibase --driver=org.postgresql.Driver --classpath=<JDBC JAR> --url=”<JDBC URL>” --changeLogFile=/liquibase/changelog/changelog.xml --username=<USERNAME> --password=<PASSWORD>`
