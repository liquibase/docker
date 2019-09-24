# docker


docker run -v <LOCAL PATH TO JDBC DRIVERS>:/liquibase/jdbc liquibase/liquibase --driver=org.postgresql.Driver --classpath=/liquibase/jdbc/postgresql-42.2.6.jar --url="jdbc:postgresql://<IP OR HOSTNAME>:<PORT>/<DATABASE>" --changeLogFile=changelog.xml --username=<USERNAME> --password=<PASSWORD> generateChangeLog
