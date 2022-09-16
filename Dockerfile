FROM eclipse-temurin:17-jre-focal

# Install GNUPG for package vefification and WGET for file download
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -yqq install krb5-user libpam-krb5 \
    && apt-get -y install gnupg wget unzip \
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
  && ln -s /liquibase/liquibase /usr/local/bin/liquibase \
  && ln -s /liquibase/bin/lpm /usr/local/bin/lpm

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=4.16.1
ARG LPM_VERSION=0.1.7

# Download, verify, extract
ARG LB_SHA256=2da0022c3315d9c59c4cb1c3b50b3bad2f5a944d74973fb9f4b32037e5403019
RUN set -x \
  && wget -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
  && echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
  && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz \
  && rm liquibase-${LIQUIBASE_VERSION}.tar.gz

# Download and Install lpm \
RUN mkdir /liquibase/bin
RUN wget -q -O lpm.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux.zip"
RUN unzip lpm.zip -d bin/
RUN rm lpm.zip
RUN export LIQUIBASE_HOME=/liquibase

# Install Drivers
RUN lpm update
RUN /liquibase/liquibase --version

COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
COPY --chown=liquibase:liquibase liquibase.docker.properties /liquibase/

VOLUME /liquibase/classpath
VOLUME /liquibase/changelog

ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["--help"]
