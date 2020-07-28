FROM openjdk:11-jre-slim-buster

# Install GPG for package vefification
RUN apt-get update \
	&& apt-get -y install gnupg wget

# Add the liquibase user and step in the directory
RUN addgroup --gid 1001 liquibase
RUN adduser --disabled-password --uid 1001 --ingroup liquibase liquibase

# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase && chown liquibase /liquibase
WORKDIR /liquibase

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=3.10.1

# Download, verify, extract
ARG LB_SHA256=e54dc5d639fa404ebcc72de647c2009748fa0685566a46abaed9c2a9b88e40e0
RUN set -x \
  && wget -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
  && echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
  && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz

# Setup GPG
RUN GNUPGHOME="$(mktemp -d)" 


# Download JDBC libraries, verify

RUN wget -O /liquibase/lib/postgresql.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.12/postgresql-42.2.12.jar \
	&& wget -O /liquibase/lib/postgresql.jar.asc https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.12/postgresql-42.2.12.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 38F47D3E410C47B1 \
    && gpg --batch --verify -fSLo /liquibase/lib/postgresql.jar.asc /liquibase/lib/postgresql.jar

RUN wget -O /liquibase/lib/mssql.jar https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/8.2.2.jre11/mssql-jdbc-8.2.2.jre11.jar \
	&& wget -O /liquibase/lib/mssql.jar.asc https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/8.2.2.jre11/mssql-jdbc-8.2.2.jre11.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 01B0B092A6925976 \
    && gpg --batch --verify -fSLo /liquibase/lib/mssql.jar.asc /liquibase/lib/mssql.jar 

RUN wget -O /liquibase/lib/mariadb.jar https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.6.0/mariadb-java-client-2.6.0.jar \
	&& wget -O wget -O /liquibase/lib/mariadb.jar.asc https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.6.0/mariadb-java-client-2.6.0.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 69B5114AA77F9D8C129AB602F8957C3395910043 \
    && gpg --batch --verify -fSLo /liquibase/lib/mariadb.jar.asc /liquibase/lib/mariadb.jar 

RUN wget -O /liquibase/lib/h2.jar https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar \
	&& wget -O wget -O /liquibase/lib/h2.jar.asc https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 0CFA413799E2464C7D7E26220A4B343F2A55FDAE \
    && gpg --batch --verify -fSLo /liquibase/lib/h2.jar.asc /liquibase/lib/h2.jar

RUN wget -O wget -O /liquibase/lib/db2.jar https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.1.4.4/jcc-11.1.4.4.jar \
	&& wget -O wget -O /liquibase/lib/db2.jar.asc https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.1.4.4/jcc-11.1.4.4.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys A18EEA8E3426F280 \
    && gpg --batch --verify -fSLo /liquibase/lib/db2.jar.asc /liquibase/lib/db2.jar

RUN wget -O /liquibase/lib/snowflake.jar https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.3/snowflake-jdbc-3.12.3.jar \
	&& wget -O wget -O /liquibase/lib/snowflake.jar.asc https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.3/snowflake-jdbc-3.12.3.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys EC218558EABB25A1 \
    && gpg --batch --verify -fSLo /liquibase/lib/snowflake.jar.asc /liquibase/lib/snowflake.jar

RUN wget -O /liquibase/lib/sybase.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/sybase/3.5.0/sybase-3.5.0.jar \
	&& wget -O /liquibase/lib/sybase.jar.asc https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/sybase/3.5.0/sybase-3.5.0.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 79752DB6C966F0B8 \
    && gpg --batch --verify -fSLo /liquibase/lib/sybase.jar.asc /liquibase/lib/sybase.jar 

RUN wget -O /liquibase/lib/firebird.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/firebird/3.5.0/firebird-3.5.0.jar \
	&& wget -O wget -O /liquibase/lib/firebird.jar.asc https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/firebird/3.5.0/firebird-3.5.0.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 79752DB6C966F0B8 \
    && gpg --batch --verify -fSLo /liquibase/lib/firebird.jar.asc /liquibase/lib/firebird.jar

RUN wget -O /liquibase/lib/sqlite.jar https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.31.1/sqlite-jdbc-3.31.1.jar \
	&& wget -O /liquibase/lib/sqlite.jar.asc https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.31.1/sqlite-jdbc-3.31.1.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 88CD390855DF292E2172DA9742575E0CCD6BA16A \
    && gpg --batch --verify -fSLo /liquibase/lib/sqlite.jar.asc /liquibase/lib/sqlite.jar 

# No key published to Maven Central, using SHA256SUM

ARG MYSQL_SHA256=f93c6d717fff1bdc8941f0feba66ac13692e58dc382ca4b543cabbdb150d8bf7
RUN wget -O /liquibase/lib/mysql.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.19/mysql-connector-java-8.0.19.jar \
	&& echo "$MYSQL_SHA256  /liquibase/lib/mysql.jar" | sha256sum -c - 

ENTRYPOINT ["/liquibase/liquibase"]