FROM openjdk:11-jre-slim-buster

# Install GNUPG for package vefification and WGET for file download
RUN apt-get update \
    && apt-get -yqq install krb5-user libpam-krb5 \
    && apt-get -y install gnupg wget \
    && rm -rf /var/lib/apt/lists/*

# Add the liquibase user and step in the directory
RUN addgroup --gid 1001 liquibase
RUN adduser --disabled-password --uid 1001 --ingroup liquibase liquibase

# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase && chown liquibase /liquibase
WORKDIR /liquibase

#Symbolic link will be broken until later
RUN ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh \
  && ln -s /liquibase/docker-entrypoint.sh /docker-entrypoint.sh \
  && ln -s /liquibase/liquibase /usr/local/bin/liquibase

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=4.4.0

# Download, verify, extract
ARG LB_SHA256=8aa5900195751f7a7d51dfba5364702297c596cbbeed213de806e1deef02095b
RUN set -x \
  && wget -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
  && echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
  && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz \
  && rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Download JDBC libraries, verify via GPG and checksum
ARG PG_VERSION=42.2.20
ARG PG_SHA1=36cc2142f46e8f4b77ffc1840ada1ba33d96324f
RUN wget --no-verbose -O /liquibase/lib/postgresql.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/${PG_VERSION}/postgresql-${PG_VERSION}.jar \
	&& wget --no-verbose -O /liquibase/lib/postgresql.jar.asc https://repo1.maven.org/maven2/org/postgresql/postgresql/${PG_VERSION}/postgresql-${PG_VERSION}.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/postgresql.jar.asc /liquibase/lib/postgresql.jar \
	&& echo "$PG_SHA1  /liquibase/lib/postgresql.jar" | sha1sum -c - 

ARG MSSQL_SHA1=7af72fb8f832634f7717f971a85ba199729b7eaa
RUN wget --no-verbose -O /liquibase/lib/mssql.jar https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/9.2.1.jre11/mssql-jdbc-9.2.1.jre11.jar \
	&& wget --no-verbose -O /liquibase/lib/mssql.jar.asc https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/9.2.1.jre11/mssql-jdbc-9.2.1.jre11.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/mssql.jar.asc /liquibase/lib/mssql.jar \
	&& echo "$MSSQL_SHA1 /liquibase/lib/mssql.jar" | sha1sum -c - 

ARG MARIADB_SHA1=4a2edc05bd882ad19371d2615c2635dccf8d74f0
RUN wget --no-verbose -O /liquibase/lib/mariadb.jar https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.7.3/mariadb-java-client-2.7.3.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/mariadb.jar.asc https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.7.3/mariadb-java-client-2.7.3.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/mariadb.jar.asc /liquibase/lib/mariadb.jar \
	&& echo "$MARIADB_SHA1 /liquibase/lib/mariadb.jar" | sha1sum -c - 

ARG H2_SHA1=f7533fe7cb8e99c87a43d325a77b4b678ad9031a
RUN wget --no-verbose -O /liquibase/lib/h2.jar https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/h2.jar.asc https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/h2.jar.asc /liquibase/lib/h2.jar \
	&& echo "$H2_SHA1 /liquibase/lib/h2.jar" | sha1sum -c - 

ARG DB2_SHA1=902856c6b9f979facc6f75fad40da6b048df5df8
RUN wget --no-verbose -O /liquibase/lib/db2.jar https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.5.5.0/jcc-11.5.5.0.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/db2.jar.asc https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.5.5.0/jcc-11.5.5.0.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/db2.jar.asc /liquibase/lib/db2.jar \
	&& echo "$DB2_SHA1 /liquibase/lib/db2.jar" | sha1sum -c -

ARG SNOWFLAKE_VERSION=3.13.5
ARG SNOWFLAKE_SHA1=5cf0b933bc7125894138bdf9befd7547e0783553
RUN wget --no-verbose -O /liquibase/lib/snowflake.jar https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/${SNOWFLAKE_VERSION}/snowflake-jdbc-${SNOWFLAKE_VERSION}.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/snowflake.jar.asc https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/${SNOWFLAKE_VERSION}/snowflake-jdbc-${SNOWFLAKE_VERSION}.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/snowflake.jar.asc /liquibase/lib/snowflake.jar \
	&& echo "$SNOWFLAKE_SHA1 /liquibase/lib/snowflake.jar" | sha1sum -c -

ARG SYBASE_SHA1=4a939221fe3023da2ddfc63ecf902a0f970d4d70
RUN wget --no-verbose -O /liquibase/lib/sybase.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/sybase/3.5.0/sybase-3.5.0.jar \
	&& wget --no-verbose -O /liquibase/lib/sybase.jar.asc https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/sybase/3.5.0/sybase-3.5.0.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/sybase.jar.asc /liquibase/lib/sybase.jar \
	&& echo "$SYBASE_SHA1 /liquibase/lib/sybase.jar" | sha1sum -c - 

ARG FIREBIRD_SHA1=40386c1fb29971ab96451a2d0c0d6aafaedea0c0
RUN wget --no-verbose -O /liquibase/lib/firebird.jar https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/firebird/3.5.0/firebird-3.5.0.jar \
	&& wget --no-verbose -O wget -O /liquibase/lib/firebird.jar.asc https://repo1.maven.org/maven2/net/sf/squirrel-sql/plugins/firebird/3.5.0/firebird-3.5.0.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/firebird.jar.asc /liquibase/lib/firebird.jar \
	&& echo "$FIREBIRD_SHA1 /liquibase/lib/firebird.jar" | sha1sum -c - 

ARG SQLITE_VERSION=3.36.0.1
ARG SQLITE_SHA1=7bd89ad11392210f8e86282004519b36d53cb9ee
RUN wget --no-verbose -O /liquibase/lib/sqlite.jar https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/${SQLITE_VERSION}/sqlite-jdbc-${SQLITE_VERSION}.jar \
	&& wget --no-verbose -O /liquibase/lib/sqlite.jar.asc https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/${SQLITE_VERSION}/sqlite-jdbc-${SQLITE_VERSION}.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/sqlite.jar.asc /liquibase/lib/sqlite.jar \
	&& echo "$SQLITE_SHA1 /liquibase/lib/sqlite.jar" | sha1sum -c - 

ARG ORACLE_SHA1=967c0b1a2d5b1435324de34a9b8018d294f8f47b
RUN wget --no-verbose -O /liquibase/lib/ojdbc8.jar https://repo1.maven.org/maven2/com/oracle/ojdbc/ojdbc8/19.3.0.0/ojdbc8-19.3.0.0.jar \
	&& wget --no-verbose -O /liquibase/lib/ojdbc8.jar.asc https://repo1.maven.org/maven2/com/oracle/ojdbc/ojdbc8/19.3.0.0/ojdbc8-19.3.0.0.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/ojdbc8.jar.asc /liquibase/lib/ojdbc8.jar \
	&& echo "$ORACLE_SHA1 /liquibase/lib/ojdbc8.jar" | sha1sum -c - 

ARG MYSQL_SHA256=a0a1be0389e541dad8841b326e79c51d39abbe1ca52267304d76d1cf4801ce96
RUN wget --no-verbose -O /liquibase/lib/mysql.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.25/mysql-connector-java-8.0.25.jar \
	&& wget --no-verbose -O /liquibase/lib/mysql.jar.asc https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.25/mysql-connector-java-8.0.25.jar.asc \
    && gpg --auto-key-locate keyserver --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve --verify /liquibase/lib/mysql.jar.asc /liquibase/lib/mysql.jar \
	&& echo "$MYSQL_SHA256  /liquibase/lib/mysql.jar" | sha256sum -c - 

COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
COPY --chown=liquibase:liquibase liquibase.docker.properties /liquibase/

VOLUME /liquibase/classpath
VOLUME /liquibase/changelog

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
