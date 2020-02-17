FROM openjdk:8-jre

MAINTAINER Datical <liquibase@datical.com>

# Install MariaDB (MySQL) and PostgreSQL JDBC Drivers for users that would like have them in the container
RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
      libmariadb-java \
      libpostgresql-jdbc-java 
# /usr/share/java/mariadb-java-client.jar
# /usr/share/java/postgresql.jar


# Add the liquibase user and step in the directory
RUN adduser --system --home /liquibase --disabled-password --group liquibase
WORKDIR /liquibase

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ENV LIQUIBASE_VERSION 3.8.6

# Download, install, clean up
RUN set -x \
  && curl -L https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz -o liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz \
  && tar -xzf liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz \
  && rm liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz 

# Set liquibase to executable
RUN chmod 777 /liquibase

ENTRYPOINT ["/liquibase/liquibase"]
CMD ["--help"]
