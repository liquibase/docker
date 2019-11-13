FROM openjdk:8-jre

MAINTAINER Datical <liquibase@datical.com>

# Add the liquibase user and step in the directory
RUN adduser --system --home /liquibase --disabled-password --group liquibase
WORKDIR /liquibase

# Change to the liquibase user
USER liquibase

ENV LIQUIBASE_VERSION 3.8.1

RUN curl -L https://repo1.maven.org/maven2/org/liquibase/liquibase-core/${LIQUIBASE_VERSION}/liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz -o liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz \
  && tar -xzf liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz \
  && rm liquibase-core-${LIQUIBASE_VERSION}-bin.tar.gz

RUN chmod 777 /liquibase

ENTRYPOINT ["/liquibase/liquibase"]
CMD ["--help"]
