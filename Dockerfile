FROM openjdk:13

MAINTAINER Datical <liquibase@datical.com>

# Install MariaDB (MySQL) and PostgreSQL JDBC Drivers for users that would like have them in the container
#RUN apt-get update \
#  && apt-get install -yq --no-install-recommends \
#      libmariadb-java \
#      libpostgresql-jdbc-java \
#  && apt-get autoclean \
#  && apt-get clean \
#  && rm -rf /var/*/apt/*
# /usr/share/java/mariadb-java-client.jar
# /usr/share/java/postgresql.jar




# Add the liquibase user and step in the directory
RUN adduser liquibase
# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase  && chown liquibase /liquibase
WORKDIR /liquibase

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=3.9.0

# Download, install, clean up
RUN set -x \
  && curl -L https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz | tar -xzf -

# RUN curl -o /liquibase/lib/<db platform>.jar <url to maven jar driver>
RUN curl -o /liquibase/lib/postgresql.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.12/postgresql-42.2.12.jar 
RUN curl -o /liquibase/lib/mssql.jar https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/8.2.2.jre13/mssql-jdbc-8.2.2.jre13.jar
RUN curl -o /liquibase/lib/mysql.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.19/mysql-connector-java-8.0.19.jar
RUN curl -o /liquibase/lib/mariadb.jar https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.6.0/mariadb-java-client-2.6.0.jar
RUN curl -o /liquibase/lib/h2.jar https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar
RUN curl -o /liquibase/lib/db2.jar https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.1.4.4/jcc-11.1.4.4.jar
RUN curl -o /liquibase/lib/snowflake.jar https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.3/snowflake-jdbc-3.12.3.jar
RUN curl -o /liquibase/lib/sybase.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/sybase/3.5.0/sybase-3.5.0.jar
RUN curl -o /liquibase/lib/firebird.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/firebird/3.5.0/firebird-3.5.0.jar

ENTRYPOINT ["/liquibase/liquibase"]
CMD ["--help"]
